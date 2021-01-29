// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/TransferHelper.sol";
import "../lib/TokenSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../ref/CoreRef.sol";
import "../interface/IRbtVip.sol";
import "../interface/IERC721Receiver.sol";

contract RainbowRbtVip is CoreRef,IRbtVip{
    using SafeMath for uint;//安全库
    using Set for Set.TokenIdSet;//set库
    string public name = "RVIP";
    string public symbol = "RVIP";
    
    uint public validity = 365 days; //令牌默认有效期
    uint256 public vipPrice;//令牌价格
    address public FoundationAddress;//基金会地址
    address public  RBTEX;//rbtex地址
    uint  private  initialNum=20090103;//初始用户注册号

    userVipStruct.Vip [] public vipArray;//全部vip

    userVipStruct.User[] public userListArray; //所有用户 
    
    mapping(address  => Set.TokenIdSet)  vipNum;//address --token集合

    mapping(address => uint) public referrerMaps;// 用户address——用户ID
    
    mapping (uint256 => address) private _tokenApprovals;// tokenId----授权的地址
    
    mapping (address => mapping (address => bool)) private _operatorApprovals;//从address 到address 的映射批准
    
    event  Register(uint indexed newId, uint indexed referrerId);//注册用户事件
    
    event Transfer(address indexed from, address indexed to, uint256  value);//ERC721 转账事件
    
    event TransferFundation(address indexed tokenAddr ,address indexed from, address indexed to, uint256 value);//基金会转账事件

    event Approval(address indexed owner, address indexed spender, uint256 value);//授权事件
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    //初始化
    constructor(uint _price,address _foundationAddress,address _rbtex,address core) CoreRef(core) public {
      vipPrice =_price;
      FoundationAddress=_foundationAddress;
      RBTEX=_rbtex;
      userVipStruct.User memory user = userVipStruct.User({
            id : initialNum, // 新用户的ID为最新ID
            addrRef : address(0),//第一个用户的推荐人为0地址
            registerTime:block.timestamp,//当前时间为注册时间
            nickname : 'admin',//admin 为默认昵称
            userAddress: msg.sender,//用户地址
            childs: new address[](0) //初始生成是0
        });
         userListArray.push(user);//加入数组
         emit Register(initialNum,0);
    }
    
    //用户注册
   function register(uint referrerId, string calldata nickname) override external {
        require(referrerMaps[msg.sender]==0,"user exists");
        uint newId = initialNum + userListArray.length;
        address  refAddress =userListArray[referrerId - initialNum].userAddress;
        userVipStruct.User memory user = userVipStruct.User({
            id : newId, // 新用户的ID为最新ID
            addrRef : refAddress,
            registerTime:block.timestamp,
            nickname : nickname,
            userAddress: msg.sender,//用户地址
            childs: new address[](0) 
        });
        userListArray.push(user);
        userListArray[referrerId-initialNum].childs.push(msg.sender);//推荐人下新增推荐到的用户
        referrerMaps[msg.sender]=newId;
        TransferHelper.safeTransfer(RBTEX, msg.sender, 1000e18);
        emit Register(newId,referrerId);
    }
    
    //兑换vip令牌(令牌数量,代币地址)
    function exchangeVip(uint vipNumber,address token) override public{
        require(vipNumber > 0,"The amount is insufficient");
        uint amount = vipNumber.mul(vipPrice);
        for(uint i = 0;i < vipNumber; i++){
         mint(msg.sender);
        }
        //vip所得的金额交管分红的基金会进行管理
        TransferHelper.safeTransferFrom(token,msg.sender,FoundationAddress,amount);
        emit TransferFundation(token,msg.sender,FoundationAddress,amount* 10 ** 18);
    }
    
    //获取vip等级  
    function getVipLevel(address addr) public view override returns (uint) {
        uint256 num=vipNum[addr].length();
        if(num == 0){
            return 0;
        }
        uint8 level = 0;
        for (uint i = 0; i < num; i++) {
            if(vipArray[vipNum[addr].at(i)-1].expireTime > block.timestamp){
                level ++;
            }
        }
        if(level<9){
           return level/3 + 1;
        }
         return 4;
      }
    
     
    //查看所有过期令牌最大token
    function getAllVipIneffective() public view  override returns (uint maxExTokenId) {
        for(uint i=0; i<vipArray.length;i++) {
             userVipStruct.Vip memory vip =vipArray[i];
             if(vip.expireTime>block.timestamp){
                 break;
             }
              maxExTokenId=vip.tokenId;
          }
    }
    
    //查看个人过期时间最大令牌的token
    function getOwerVipIneffective(address addr) public view override returns (uint maxOwnerExTokenId) {
      uint num=vipNum[addr].length();
      uint maxOwnerExpireTime=vipArray[vipNum[addr].at(0)-1].expireTime;
      for(uint i=0; i<num; i++){
       if( vipArray[vipNum[addr].at(i)-1].expireTime > maxOwnerExpireTime){
           maxOwnerExpireTime=vipArray[vipNum[addr].at(i)-1].expireTime;
           maxOwnerExTokenId=vipArray[vipNum[addr].at(i)-1].tokenId;
          }
      }
    }

    //查询令牌所有人
    function ownerOf(uint256 tokenId) public view override returns(address){
       return  vipArray[tokenId-1].owner;
    }
    
    //查询令牌的详情
     function  getVipInfo(uint256 tokenId) public view  override returns(userVipStruct.Vip memory ){
        return  vipArray[tokenId-1];
    }

    //查询用户的详情
    function  getUserInfo(address addr) public view override  returns(userVipStruct.User memory ){
        if(referrerMaps[msg.sender]!=0){
          return  userListArray[referrerMaps[addr]-initialNum]; 
        }
    }
    
    //增发令牌
    function mint(address to) internal returns(uint) {
       require(to != address(0), "ERC721: mint to the zero address");
         uint256 newTokenId = vipArray.length+1;
            userVipStruct.Vip memory vip = userVipStruct.Vip({
                owner: to,
                creator:to,
                tokenId: newTokenId,
                expireTime: block.timestamp+validity,
                crtTime:block.timestamp
            });
            vipArray.push(vip);
            vipNum[msg.sender].add(newTokenId);
            emit Transfer(address(0), to,newTokenId);
            return newTokenId;
      }
    
     // 管理员给用户赠送令牌
     function sendVipByWhiteList (address[] memory addr,uint [] memory amount) onlyGovernor public  {
         require(addr.length==amount.length,"ArrayLenght err,The length should be the same");
         for(uint i=0;i<addr.length;i++){
          for(uint j = 0;j< amount[i]; j++){
             mint(addr[i]);
           }
         }
     }

    //获取用户令牌的token
     function tokenOfOwnerByIndex(address owner,uint index) public override view returns(uint){
        return vipNum[owner].at(index);
    }
    
    //获取一个用户拥有多少令牌
     function balanceOf(address addr) public view override returns(uint){
      return vipNum[addr].length();
    }
    
    //获取总共增发token数量
    function totalSupply() public view override returns(uint){
      return vipArray.length;
    }
    
    //进行授权
     function approve(address to, uint256 tokenId) public  override {
        address ownerAddr =vipArray[tokenId-1].owner;
        require(to != ownerAddr, "ERC721: approval to current owner");
        require(msg.sender == ownerAddr , "ERC721: approve caller is not owner " );
        _tokenApprovals[tokenId] = ownerAddr;
        emit Approval(ownerAddr,to,tokenId);
    }
    
    //转账
    function transfer(address from, address to, uint256 tokenId) public override {
         require(from != address(0), "ERC20: transfer from the zero address");
         require(to != address(0), "ERC20: transfer to the zero address");
         vipNum[from].remove(tokenId);
         vipNum[to].add(tokenId);
         vipArray[tokenId-1].owner=to;
         emit Transfer(from,to,tokenId);
    }

    //转移NFT所有权
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    //转移NFT所有权
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    //授予地址_operator具有所有NFTs的控制权
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //用来是否查询授权
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

   //用来查询授权
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(vipArray[tokenId-1].owner!=address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

   //内部函数,调用在目标地址,如果目标地址不是协定，则不执行调用。
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } 
         return true;
    }
    
     function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}
pragma solidity ^0.8.0;
import "../interface/token721/IRbtDeposit721.sol";
import "../lib/TokenSet.sol";
import "../interface/token721/IERC721Receiver.sol";
import "../interface/bank/IRbBank.sol";
import "../ref/CoreRef.sol";

    //存款令牌
    contract RbtDeposit721 is CoreRef,IRbtDeposit721 {
        using Set for Set.TokenIdSet;//set库
        struct Deposit{
            address owner;
            uint tokenId;
            uint startTime;
            uint expireTime;
            uint amount;
    }
    
     //构造函数
    constructor(address core)CoreRef(core){}
    
    function init(address _bank) external {
        bank =_bank;
    }

    //银行地址
    address bank;
    //令牌总个数
    uint Lengths;
    Deposit[] private list ;
    mapping(address=>Set.TokenIdSet) userToken ;
    mapping (uint256 => address) private _tokenApprovals;// tokenId----授权的地址
    //再授权时，从所有者到操作者的映射
    mapping (address => mapping (address => bool)) private _operatorApprovals;
   
    /*
    * 增发令牌，只限制银行可以增发令牌（_isBank）获得凭证。
    */
    function mint(address to,  uint amounts, uint month) onlyBank external override returns(uint) {
        //当前区块的时间，在unit32范围内
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        //增发一个新令牌，该地址下令牌数量加1
        uint256 tokenId = list.length+1;
        uint expireTime=blockTime +(month*2592000);
        Deposit memory record = Deposit({
            owner : to,
            tokenId : tokenId,
            startTime:blockTime,
            expireTime:expireTime,
            amount: amounts
        });
        list.push(record);
        Lengths=list.length;
        userToken[to].add(tokenId);
        return  tokenId;
    }

    //销毁令牌
    function burn(uint256 tokenId) onlyBank external override  virtual {
        address owner = ownerOf(tokenId);
        userToken[owner].remove(tokenId);
        delete list[tokenId-1];
        Lengths=list.length-1;
        emit Transfer(owner, address(0), tokenId);
    }
    
    //根据tokenid找到所有者地址
    function ownerOf(uint256 _tokenId) public view override returns (address owner){
        owner=list[_tokenId-1].owner;
    }
    //发行令牌总数
    function totalSupply() public view returns (uint256 totalSupply){
        totalSupply=Lengths;
    }

    //用户的令牌数量
    function balanceOf(address _owner) public view override returns (uint balance){
        balance=userToken[_owner].length();
    }

    //查询令牌押质押数
    function amount(uint256 tokenId) public view override returns(uint){
        return  list[tokenId-1].amount;
    }
    
     //查询令牌有效期
    function expire(uint256 tokenId) public view override returns(uint){
        return  list[tokenId-1].expireTime;
    }
    
    //tokenId是否存在
    function _exists(uint256 tokenId) public view override returns (bool) {
        return list[tokenId].owner != address(0);
    }
    
     //查询用户下tokenid列表中的任意一个token
     function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return userToken[owner].at(index);
    }
    
    //查看令牌信息
    function tokenMetadata(uint _tokenId) public view  returns (Deposit memory ) {
        return list[_tokenId-1];
    }

    //令牌转移
    function transfer(address _from, address _to, uint256 _tokenId) public  {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        userToken[_from].remove(_tokenId);
        userToken[_to].add(_tokenId);
        list[_tokenId-1].owner=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    //授予地址_to具有_tokenId的控制权，方法成功后需触发Approval 事件。   
    function approve(address _to, uint256 _tokenId)public override {
        require(msg.sender == list[_tokenId].owner);
        require(msg.sender != _to);//授权的目标不是自己
        _tokenApprovals[_tokenId] = _to;
        emit Approval(list[_tokenId].owner, _to, _tokenId);
    }
    
    //获得批准的地址
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
     //用来查询授权
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    
    //授予地址_operator具有所有NFTs的控制权，成功后需触发ApprovalForAll事件。
    function setApprovalForAll(address operator, bool approved) public override virtual  {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
     //用来查询授权
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    //转移NFT所有权
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override virtual   {
        transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    //转移NFT所有权
    function safeTransferFrom(address from, address to, uint256 tokenId) public override virtual  {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    //内部函数,调用在目标地址,如果目标地址不是协定，则不执行调用。
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
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

    //是否是contract地址
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    //修饰器用来检查调用者是否是银行
    modifier onlyBank {
        require(msg.sender==bank, "is not bank");
        _;
    }
}
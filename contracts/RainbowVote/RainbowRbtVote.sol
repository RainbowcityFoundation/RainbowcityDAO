pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../ref/CoreRef.sol";
import "../interface/IRbtVote.sol";
import "../interface/IRbtVip.sol";
//import "../interface/token20/IERC20.sol";
import "../interface/IVoteOracle.sol";
//import "../interface//gov/IBlockNumber.sol";

contract RainbowRbtVote is CoreRef,IRbtVote{

    using SafeMath for uint;//安全库

    address  public rvipAddr;//rvip合约地址
    
    address public shoppingAddr ;//市场合约地址
    
    struct OracleVote{
     address  contractAddr;
     uint     ratioFactor;
    }
   
    OracleVote [] oracleVoteArray;
   
    struct Vote{
      address owner; //拥有者
      uint tokenId; //tokenId号
      uint crtTime;//生成时间
    }

    constructor(address _rVip,address core) CoreRef(core) public {
      rvipAddr=_rVip;
    }

    Vote [] public voteArray;//全部vote
    
    mapping (address => uint) public takenByAddr;  //uint --tokenId
    
    mapping (address =>mapping (uint256 =>uint)) public  originalVote;//地址=>提案号=> 原始生成的票数
    
    mapping (address =>mapping (uint256 =>uint)) public  commissionedVote;//地址=>提案号=>委托进来票数
    
    mapping (address =>mapping (uint256 =>uint)) public  delegateVote;//地址=>提案号=>委托出去的票数
    
    mapping (address =>mapping(address =>mapping (uint256 =>uint))) public  toDelegateVote;//委托地址=>被委托地址=>提案号=>委托出去的票数

    mapping(uint => uint) public everyVoteDelegateAmount; //每个竞选总共委托的数量 总委托票数
    
    event Transfer(address indexed from, address indexed to, uint256 value);//ERC721 转账事件

    event DelegateEvent(uint indexed campaignId,address indexed sender,address indexed received,uint amount);//委托事件
    
    event Approval(address indexed owner, address indexed spender, uint256 value);//授权事件
    
    event UndoDelegateEvent(uint indexed campaignId,address indexed sender,address indexed received);//取消委托事件
  
    event  ChangeShoppingAddrEvent(address indexed originAddr,address indexed newAddr);//更改市场合约地址事件
    
    event  ChangeRbVipAddrEvent(address indexed originAddr,address indexed newAddr);//更改rbVip地址事件

    //生成
    function mint(address to) public returns(uint){
       require(to != address(0), "ERC721: mint to the zero address");
       require(takenByAddr[to]==0,"Additional tokens have been issued");
         uint256 newTokenId = voteArray.length+1;
             Vote memory vote = Vote({
                owner: to,
                tokenId: newTokenId,
                crtTime:block.timestamp
            });
            voteArray.push(vote);
            takenByAddr[to]=newTokenId;
            emit Transfer(address(0), to,newTokenId);
            return newTokenId;
      }
      
    //管理员更改市场合约地址
     function setShoppingAddr (address  addr) onlyGovernor public  {
         emit ChangeShoppingAddrEvent(shoppingAddr,addr);
         shoppingAddr=addr;
     }

    //管理员更改rbVip地址
     function setRbVipAddr (address  _rVip) onlyGovernor public  {
        emit ChangeRbVipAddrEvent(rvipAddr,_rVip);
         rvipAddr=_rVip;
     }

    //获取rbVip等级
    function getRbVipLevel (address addr)public view returns(uint){    
   //rbVIP会员等级
     IRbtVip RbVip = IRbtVip(rvipAddr);
     return  RbVip.getVipLevel(addr);//VIP等级 
   }
   
     //取得某一提案某用户原始的总票数
    function  setOriginalVote(address to,address govAddr,uint cityNodeId,uint blockNumber,uint campaignId) public {
         //治理提交可用
        // IBlockNumber  gov =IBlockNumber(govAddr);
        // uint blockNumber=gov.getBlockNumber(cityNodeId);
        originalVote[to][campaignId]=getVoteNum(to,blockNumber);
    }

    //委托
   function delegate(address from,address to,uint amount,uint campaignId) public {
        require(from==msg.sender,"have no right");
        require(originalVote[from][campaignId]-delegateVote[from][campaignId]>0,"Insufficient votes");
         commissionedVote[to][campaignId]+=amount;
         everyVoteDelegateAmount[campaignId] += amount;
         delegateVote[from][campaignId]+=amount;
         toDelegateVote[from][to][campaignId]+=amount;
         emit DelegateEvent(campaignId,from,to,amount);
   }
   
    //撤回委托,   委托给某人多笔，执行操作,将全部的票数进行撤回
     function undoDelegate(address from ,address to,uint campaignId) public {
       //撤回只有自己有权调用
       require(from==msg.sender,"have no right");
       //撤销回来的加回到原始的票数
       originalVote[from][campaignId]+=toDelegateVote[from][to][campaignId];
       //委托记录的减出来
       delegateVote[from][campaignId]-= toDelegateVote[from][to][campaignId];
       //把撤回的记录进行清零
       toDelegateVote[from][to][campaignId]=0;

       everyVoteDelegateAmount[campaignId] -= toDelegateVote[from][to][campaignId];
     emit UndoDelegateEvent(campaignId,from,to);
   }
   
    //获取到在某一提案下，用户持有的票数=自身的原始票数+收到委托的票数-委托出去的票数
     function getBalanceOf(address addr,uint campaignId)public view returns (uint){
      return  originalVote[addr][campaignId] +commissionedVote[addr][campaignId]-delegateVote[addr][campaignId];
     }

      //查询令牌所有人
    function ownerOf(uint256 tokenId) public view override returns(address){
      return  voteArray[tokenId-1].owner;
    }

    //查询委托的票数
    function getcommissionedVotes(address addr,uint campaignId)public view override returns (uint){
      return  commissionedVote[addr][campaignId];
    }
    //查询委托的总票数
    function getDelegateVote(uint campaignId) external view override returns(uint){
        return everyVoteDelegateAmount[campaignId];
    }

    //投票减票
    function subcommissionedVotes(address addr,uint campaignId,uint amount) external override{
      require(commissionedVote[addr][campaignId]>=amount,"Insufficient votes");
      commissionedVote[addr][campaignId]=commissionedVote[addr][campaignId]-amount;
    }

    
      //获取一个用户拥有多少令牌
    function balanceOf(address addr) public view override returns(uint){
      return takenByAddr[addr]>0 ? 1 : 0;
    }
    
      //获取总共增发token数量
    function totalSupply() public view override returns(uint){
      return voteArray.length;
    }
    
    //进行授权
     function approve(address to, uint256 tokenId) public  override {
      require(true, "Authorization is not supported");
    }
    
    //转账
    function transfer(address from, address to, uint256 tokenId) public override {
     require(true,"Not at least transfer");
    }
    
    //转移NFT所有权
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override  {
        transfer(from,to,tokenId);
    }
    
    //转移NFT所有权
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
       safeTransferFrom(from,to,tokenId, "");
    }

    //授予地址_operator具有所有NFTs的控制权
    function setApprovalForAll(address operator, bool approved) public virtual override {
      require(true, "Authorization is not supported");
    }

   //用来是否查询授权
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      require(true, "No authorization is pending");
    }

   //用来查询授权
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
      require(true, "No authorization is pending");
    }

   //配置要查询的合约地址和基础权重比例
   function  setPriorVotes (address[] memory addrArray,uint [] memory ratioArray)  override public{
        delete oracleVoteArray;
        require(addrArray.length==ratioArray.length,"The array length is inconsistent");
        for(uint i=0;i<addrArray.length;i++){
          for(uint j = 0;j< ratioArray.length; j++){
              if(i==j){
                  OracleVote memory oracleVote = OracleVote({
                     contractAddr: addrArray[i],
                     ratioFactor: ratioArray[j]
                  });
                oracleVoteArray.push(oracleVote);
            }
         }
     }
         
   }
   
   //根据用户地址和区块计算权重
   function  getVoteNum(address account, uint blockNumber) public view returns (uint num) {
     for(uint i=0;i<oracleVoteArray.length;i++){
       IVoteOracle RbVoteOracle = IVoteOracle(oracleVoteArray[i].contractAddr);
       num+=RbVoteOracle.getPriorVotes(account,blockNumber)*oracleVoteArray[i].ratioFactor;
     }
   }
}

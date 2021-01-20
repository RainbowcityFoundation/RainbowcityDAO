pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../ref/CoreRef.sol';
import "../lib/TransferHelper.sol";
import "../interface/gov/ICityNodeFundManagement.sol";
import "../interface/gov/IParliament.sol";
import '../interface/IRbtVote.sol';

// import '../interface/gov/ICityNodeFundManagement.sol';
contract CityNodeFundManagement is CoreRef,ICityNodeFundManagement{
    //todo  调用core验证来源自citynode
    using SafeMath for uint256;
    mapping(string =>mapping(address=>uint)) public tokenStorage; //每个选项的代币存储
    mapping(address =>mapping(address => uint)) public managerAndParliamentsReward;
    uint tokenProposalCount;
    struct tokenProposal{
        uint id;
        address owner;
        uint nodeId;
        uint stage;
        uint day;
        uint depositType;
        uint applyAmount;
        uint depositAmount;
        uint opposeTickets;
        string  description;
        uint parliamentsAgree;
        uint creationTime;
        uint voteStartTime;
        mapping(uint => stageDetails) everyStageDetails;
    }
    struct parliamentsVoteRecord{
        address[]  parliaments;
        mapping(address => bool) parliamentsVoted;
    }
    //提案id 分次id 议员地址 是否投票
    mapping(uint =>mapping(uint => parliamentsVoteRecord) ) private  parliamentsVote;
    struct stageDetails {
        bool start;
        uint oppose;
        bool received;//是否收到这一阶段的钱
        bool canSubmit; //是否可以提交说明
        uint startTime;
        uint againSecond; //被拒绝重新申请的次数
        string  description;
//        mapping(address=>bool) parliamentsVote;
    }
    mapping(uint => tokenProposal) public tokenProposals;
    IRbtVote public RbtVote;
    address public fundOwner;
    event tokenProposalCreate(uint indexed id, uint indexed nodeId,address owner,uint creationTime);

    constructor(address nodeAddress,address core,address token) public  CoreRef(core)  {
        uint256 maxTokens = type(uint256).max;
         fundOwner = nodeAddress;
        // IERC20(token).approve(nodeAddress, maxTokens);
    }


    modifier _inNode(uint nodeId,address sender) {
        require(IParliament(fundOwner).inNode(nodeId,sender) == true);
        _;
    }
    function setRbtVote(address addr) public  onlyGovernor() {
        RbtVote = IRbtVote(addr);
    }
    /*
     @dev 使用资金
      @params receiver 接收人
      @params amount 数量
      @params where 从那种类型里打
      @params token 哪种代币
 */
    function _extract(address receiver,uint[] memory amount,string[] memory where,address token) internal {
        require(amount.length == where.length);
        uint allAmount;
        for(uint i = 0; i<amount.length; i++){
            require(tokenStorage[where[i]][token] >= amount[i]);
            allAmount=allAmount.add(amount[i]);
            tokenStorage[where[i]][token] = tokenStorage[where[i]][token].sub(amount[i]);
        }
        IERC20(token).transfer(receiver,allAmount);
    }

    /*
      @dev 弹劾资金发放计算
      @params receiver 接收人
      @params amount 数量
      @params token 哪种代币
    */
    //todo  调用core验证来源需要来自citynode
    function impeachTokenSend(address receiver,uint amount,address token,uint impeachtype) external override onlyCityNode() {
        string[] memory where = new string[](2);
        uint[] memory portion = new uint[](2) ;
        string memory origin = '';
        if(impeachtype == 1) {
            string memory origin = 'MANAGER_STORE';
        }else if(impeachtype == 2){
            string memory origin = 'PARLIAMENT_STORE';
        }
        if (amount > tokenStorage[origin][token]) {
            where[0] = origin;
            portion[0] = tokenStorage[origin][token];
            uint leftToken = amount - tokenStorage[origin][token];
            if(leftToken > tokenStorage['PUBLIC_STORE'][token]){
                leftToken = tokenStorage['PUBLIC_STORE'][token];
            }
            where[1] = 'PUBLIC_STORE';
            portion[1] = leftToken;
        } else {
            where[0] = origin;
            portion[0] = amount;
        }
        _extract(receiver,portion,where,token);
    }

    /*
        @dev 申请资金
        @params tokenProposal

    */
    function applyToken(uint nodeId,uint stage,uint day ,uint depositType,uint applyAmount,uint depositAmount,string memory description) external  _inNode(nodeId,msg.sender){
        tokenProposalCount++;
        if(depositType == 1){
            require(depositAmount == 100);
        }else if(depositType == 2) {
            require(depositAmount == applyAmount.mul(5).div(100));
        }

        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,address(this),depositAmount);
        tokenProposal storage c = tokenProposals[tokenProposalCount];
        c.id = tokenProposalCount;
        c.owner = msg.sender;
        c.nodeId = nodeId;
        c.stage = stage;
        c.day = day;
        c.depositType = depositType;
        c.applyAmount = applyAmount;
        c.depositAmount = depositAmount;
        c.description = description;
        c.parliamentsAgree = 0 ;
        c.creationTime = block.timestamp;
      
        emit tokenProposalCreate(c.id,nodeId,msg.sender,block.timestamp);
    }

    /*
        @dev设置存款记账
    */
    //todo 验证来源
    function addTokenStorage(string memory store, address token, uint amount) external override{
        tokenStorage[store][token] = tokenStorage[store][token].add(amount);
    }

    /*
          @dev 议会给分组投票
          @params nodeId 节点id
          @params id 提案id
          @params stage 提案第几步
      */
    function parliamentsVoteProposal (IParliament Ip,uint nodeId,uint id,uint stage) external  _inNode(nodeId,msg.sender) {
       
        (, ,address manager , uint voteId ) = Ip.getCityNodeInfo(nodeId);
        require(stage>=0 && stage<=tokenProposals[id].stage,'not in stage');
        require(Ip.hasParliament(nodeId,msg.sender) || manager == msg.sender);
        require(parliamentsVote[id][stage].parliamentsVoted[msg.sender] == false,'voted');
        parliamentsVote[id][stage].parliamentsVoted[msg.sender] = true;
        parliamentsVote[id][stage].parliaments.push(msg.sender);
        if(stage == 0) {
            require(block.timestamp < tokenProposals[id].creationTime + 3 days ,'not in time');
            tokenProposals[id].parliamentsAgree++;
            if(tokenProposals[id].parliamentsAgree == 7) {
                tokenProposals[id].voteStartTime == block.timestamp;
                tokenProposals[id].everyStageDetails[1].startTime = block.timestamp + 7 days;
            }
            require(tokenProposals[id].parliamentsAgree <= 7 ,'this proposal is adopt');
        } else {

            uint  allticket = RbtVote.getDelegateVote(voteId);
//            uint allticket = 100;
            if(stage == 1) {
                require(tokenProposals[id].parliamentsAgree == 7 && tokenProposals[id].opposeTickets < allticket.mul(30).div(100),'prev stage is not finished');
            }else{
                require(tokenProposals[id].everyStageDetails[stage-1].oppose < 7 &&
                    block.timestamp > tokenProposals[id].everyStageDetails[stage-1].startTime + 3 days,'');
            }
            tokenProposals[id].everyStageDetails[stage].oppose++;
            if(tokenProposals[id].everyStageDetails[stage].oppose == 7) {
                //没通过
                require(tokenProposals[id].everyStageDetails[stage].againSecond <= 3 ,' no chance');
                tokenProposals[id].everyStageDetails[stage].oppose = 0;
                tokenProposals[id].everyStageDetails[stage].againSecond++;
                tokenProposals[id].everyStageDetails[stage].canSubmit = true;
              
                uint voteLength = parliamentsVote[id][stage].parliaments.length;
                for(uint i = 0; i< voteLength;i++){
                    delete parliamentsVote[id][stage].parliamentsVoted[parliamentsVote[id][stage].parliaments[i]];
                }
                delete parliamentsVote[id][stage].parliaments;
            }
        }
    }

    /*
      @dev 给提案投反对票
      @params id 提案id
      @params tickets 投多少票
    */
    function voteToProposal(uint nodeId, uint id,uint tickets) external  _inNode(nodeId,msg.sender) {
        require(tokenProposals[id].voteStartTime + 7 days > block.timestamp && tokenProposals[id].parliamentsAgree == 7);
        tokenProposals[id].opposeTickets = tokenProposals[id].opposeTickets.add(tickets);
    }


    /*
          @dev 对提案打钱
      @params id 提案id
      @params tickets 投多少票
    */
    function receiveToken(IParliament Ip,uint id,uint stage) external   {
        (, ,address manager , uint voteId ) = Ip.getCityNodeInfo(tokenProposals[id].nodeId);
        require(stage>0 && stage<=tokenProposals[id].stage,'not in stage');
        require(tokenProposals[id].owner == msg.sender);
        require(tokenProposals[id].everyStageDetails[stage].received == false,'no access to receive');
        if(stage == 1) {
            uint  allticket = RbtVote.getDelegateVote(voteId);
//            uint allticket = 100;
            require(block.timestamp < tokenProposals[id].creationTime + 3 days ,'not in time');
            require(tokenProposals[id].parliamentsAgree == 7);
            require(tokenProposals[id].opposeTickets < allticket.mul(30).div(100));
        }else {
            require(tokenProposals[id].everyStageDetails[stage -1].oppose < 7 && tokenProposals[id].everyStageDetails[stage - 1].startTime + tokenProposals[id].day < block.timestamp);
        }

        tokenProposals[id].everyStageDetails[stage].received = true;
        tokenProposals[id].everyStageDetails[stage].canSubmit = true;
        if(tokenProposals[id].stage >= stage + 1) {
            tokenProposals[id].everyStageDetails[stage+1].startTime = block.timestamp;
        }
        string[] memory where = new string[](1);
        uint[] memory portion = new uint[](1);
        where[0] = 'PUBLIC_STORE';
        portion[0] = tokenProposals[id].applyAmount.div(tokenProposals[id].stage);
        IERC20 rbt = core().rbt();
        _extract(msg.sender,portion,where,address(rbt));
    }

    /*
        @dev 提交报告
        @params 提交
        @params
    */
    function submitReport(uint id,uint stage,string memory description) public {
        require(stage > 0 && stage <= tokenProposals[id].stage);
        require(tokenProposals[id].everyStageDetails[stage].canSubmit == true , 'Cannot submit at this time');
        tokenProposals[id].everyStageDetails[stage].description = description;
        tokenProposals[id].everyStageDetails[stage].canSubmit = false;
    }
    //todo  调用core验证来源
    function setUserReward(address user ,address token ,uint amount,uint operate) public override {
        require(operate == 1 || operate == 2,'not access');
        if (operate == 1) {
           managerAndParliamentsReward[user][token] =  managerAndParliamentsReward[user][token].add(amount);
        }else if(operate == 2){
            managerAndParliamentsReward[user][token] =  managerAndParliamentsReward[user][token].sub(amount);
        }
    }

    /*
        @dev获取用户剩余的奖励
        @params user 账户
        @params token 哪个代币
        @return 数量
    */
    function getUserReward(address user,address token) public view override returns(uint) {
        return managerAndParliamentsReward[user][token];
    }


}

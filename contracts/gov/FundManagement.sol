pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../lib/TransferHelper.sol";
import '../ref/CoreRef.sol';
import '../ref/VoteIdRef.sol';
import '../interface/gov/IParliament.sol';
import '../interface/gov/ICommunityGovernanceFund.sol';
import '../interface/gov/IFundManagement.sol';
import '../interface/IRbtVote.sol';
contract FundManagement is CoreRef,VoteIdRef,IFundManagement{

    using SafeMath for uint256;
    uint tokenProposalCount;
    struct tokenProposal{
        uint id;
        address owner;
        uint stage;
        uint day;
        uint depositType;
        uint applyAmount;
        uint depositAmount;
        uint voteId;
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
    
    struct proposalFrom{
        uint id;
        ICommunityGovernanceFund cg;
        IParliament ip;
    }
    mapping(uint => proposalFrom) public  proposalFroms;

    IRbtVote public RbtVote;
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

    event tokenProposalCreate(uint indexed id,address owner,uint creationTime);


    constructor(address core,address voteIdAddr)   CoreRef(core)  VoteIdRef(voteIdAddr) {}

    function setRbtVote(address addr) public  onlyGovernor() {
        RbtVote = IRbtVote(addr);
    }


    /*
       @dev 申请资金
       @params tokenProposal

   */
    function applyToken(IParliament ip,uint nodeId,uint stage,uint day ,uint depositType,uint applyAmount,uint depositAmount,string memory description) public  {
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
        c.stage = stage;
        c.voteId = IVoteId(voteIdAddress).incrVoteId();
        c.day = day;
        c.depositType = depositType;
        c.applyAmount = applyAmount;
        c.depositAmount = depositAmount;
        c.description = description;
        c.parliamentsAgree = 0 ;
        c.creationTime = block.timestamp;
        proposalFroms[c.id].id = nodeId;
        proposalFroms[c.id].ip = ip;
        emit tokenProposalCreate(c.id,msg.sender,block.timestamp);
    }

    /*
           @dev 基金会申请资金
           @params tokenProposal

       */
    function comGovApplyToken(ICommunityGovernanceFund cg,uint stage,uint day ,uint depositType,uint applyAmount,uint depositAmount,string memory description) public {
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
        c.stage = stage;
        c.day = day;
        c.depositType = depositType;
        c.applyAmount = applyAmount;
        c.depositAmount = depositAmount;
        c.description = description;
        c.parliamentsAgree = 0 ;
        c.creationTime = block.timestamp;
        c.voteId = IVoteId(voteIdAddress).incrVoteId();
        proposalFroms[c.id].cg = cg;
        emit tokenProposalCreate(c.id,msg.sender,block.timestamp);
    }

    /*
          @dev 议会给分组投票
          @params nodeId 节点id
          @params id 提案id
          @params stage 提案第几步
      */
    function parliamentsVoteProposal(uint id,uint stage) external override  {
        uint nodeId = proposalFroms[id].id;
        uint voteId = 0;
        if(nodeId != 0) {
            IParliament ip = proposalFroms[id].ip;
            (, ,address manager , uint voteIdFrom ) = ip.getCityNodeInfo(nodeId);
            require(ip.hasParliament(nodeId,msg.sender) || manager == msg.sender,'no access');
            voteId = voteIdFrom;
        }else{
            ICommunityGovernanceFund cg = proposalFroms[id].cg;
            (,address manager,uint voteIdFrom ,,,,)= cg.cgInfo();
            require(cg.hasParliament(msg.sender) || manager == msg.sender,'no access');
            voteId = voteIdFrom;
        }

        require(stage>=0 && stage<=tokenProposals[id].stage,'not in stage');

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
    function voteToProposal(uint id,uint tickets) public  {
        require(tokenProposals[id].voteStartTime + 7 days > block.timestamp && tokenProposals[id].parliamentsAgree == 7);
        tokenProposals[id].opposeTickets = tokenProposals[id].opposeTickets.add(tickets);
    }


    /*
          @dev 对提案打钱
      @params id 提案id
      @params tickets 投多少票
    */

    function receiveToken(uint id,uint stage) external override returns(string[] memory where,uint[] memory portion )  {
        require(stage>0 && stage<=tokenProposals[id].stage,'not in stage');
        require(tokenProposals[id].owner == msg.sender);
        require(tokenProposals[id].everyStageDetails[stage].received == false,'no access to receive');

        uint nodeId = proposalFroms[id].id;
        uint voteId = 0;
        if(nodeId != 0) {
            IParliament ip = proposalFroms[id].ip;
            (, ,address manager , uint voteIdFrom ) = ip.getCityNodeInfo(nodeId);
            voteId = voteIdFrom;
        }else{
            ICommunityGovernanceFund cg = proposalFroms[id].cg;
            (,address manager,uint voteIdFrom ,,,,)= cg.cgInfo();
            voteId = voteIdFrom;
        }
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

        if(nodeId != 0) {
            IParliament ip = proposalFroms[id].ip;
        }else{
            ICommunityGovernanceFund cg = proposalFroms[id].cg;
            cg.applyTokenExtract(msg.sender,portion,where,address(Rbt()));
        }
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
}

pragma solidity ^0.8.0;

import './CityNodeRef.sol';
import '../interface/gov/IImpeach.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../interface/gov/IGovernanceCommittee.sol';
import '../interface/gov/IParliament.sol';
import '../interface/gov/ICommunityGovernanceFund.sol';
import "../ref/CoreRef.sol";
import '../interface/IRbtVote.sol';
contract Vote is CityNodeRef,CoreRef {
    using SafeMath for uint256;
    IImpeach public ImpeachRef;

    IRbtVote public RbtVote;
    constructor(address nodeAddress,address core) public  CityNodeRef(nodeAddress) CoreRef(core)  {}

    function setImpeachAddr(address addr) public  onlyGovernor() {
        ImpeachRef = IImpeach(addr);
    }
    function setRbtVote(address addr) public  onlyGovernor() {
        RbtVote = IRbtVote(addr);
    }



    function _subVotes(address user,uint voteId,uint amount) internal {
       uint allTickets =  RbtVote.getcommissionedVotes(user,voteId);
       require(allTickets >= amount,'not enough');
        RbtVote.subcommissionedVotes(user,voteId,amount);
    }

    /*
     @dev 投票
     @params nodeId 节点ID
     @params receiver 投给谁
     @params tickets 票数

 */
    function vote(uint nodeId,address receiver,uint tickets,uint voteType) external  _inNode(nodeId,msg.sender)  {

        if(voteType == 1){
            (bool votePeriod, uint expireTime, , uint nodeVoteId ) = Ip.getCityNodeInfo(nodeId);

            require(votePeriod,'not in vote time');
            //todo for test close
             require(expireTime + 14 days < block.timestamp && expireTime + 21 days > block.timestamp,'not in time');
            require(cityNode.getExistsApplyUsers(nodeId,nodeVoteId,receiver),'no have this receiver');

            _subVotes(msg.sender,nodeVoteId,tickets);
            cityNode.voteToManager( nodeId,nodeVoteId,receiver,tickets);
        }else if(voteType == 2){
            (uint expireTime, bool votePeriod,) = Ip.parliamentInfo(nodeId);
            require(votePeriod == true,'not in vote time');
            uint voteId = Ip.getApplyParliamentVoteId(nodeId);
            (uint applyLength) = Ip.getApplyParliament(nodeId,voteId);
             //todo for test close
             require(applyLength >= 15 && expireTime + 7 days > block.timestamp,'not enough');
            _subVotes(msg.sender,voteId,tickets);
            Ip.voteToParliament(nodeId,voteId,receiver,tickets);
        }
    }
    /*
      @dev 结束投票
      @params nodeId 节点ID
    */
    function endVote(uint nodeId,uint votetype) external  _inNode(nodeId,msg.sender){
        if(votetype == 1){
            (bool votePeriod,uint expireTime , , uint voteId)= Ip.getCityNodeInfo(nodeId);
            require(votePeriod,'not in vote time');
            require( expireTime + 21 days < block.timestamp,'not in time');
            cityNode.endToManager(nodeId,voteId);
        }else if(votetype == 2){
            (uint expireTime,bool votePeriod,) = Ip.parliamentInfo(nodeId);
             require(votePeriod,'not in vote time');
             uint voteId = Ip.getApplyParliamentVoteId(nodeId);
             cityNode.endToParliament(nodeId,voteId);
        }
     
    }

    /*
        @dev给弹劾投票
         @params id 弹劾id
         @params tickets 票数
    */
    function voteToImpeach(uint id,uint tickets) public {
        PublicStructs.Impeach memory im = ImpeachRef.getImpeach(id);
        require(im.success == false,'is end');
        require(block.timestamp < im.creationTime + 7 days);

        _subVotes(msg.sender,im.voteId,tickets);

        ImpeachRef.setImpeachTickets(id,tickets);

        uint  allTickets = RbtVote.getDelegateVote(im.voteId);
        //弹劾成功
        if(im.tickets.add(tickets) > allTickets.mul(30).div(100)){
            im.success = true;
            ImpeachRef.setImpeachSuccess(id);
            if(im.nodeId != 0){
                IParliament icn = im.icn;
                ( ,  , , uint nodeVoteId)= icn.getCityNodeInfo(im.nodeId);
                if(im.impeachtype == 1){
                    icn.setManagerInfo(im.nodeId,address(0));
                }else if(im.impeachtype == 2){
                    //离任
                    icn.removeParliament(im.nodeId,im.acceptor);
                    //上任
                    uint voteId = icn.getApplyParliamentVoteId(im.nodeId);
                    (,,uint impeachIndex) = icn.parliamentInfo(im.nodeId);
                    icn.setParliament(im.nodeId,voteId,impeachIndex+1);
                }
                icn.impeachExtract(im.nodeId,address(Rbt()),im.amount * 5,im.sponsor,im.impeachtype);
            }else{
                //弹劾四大基金会
                ICommunityGovernanceFund gov = im.gov;
                (uint expireTime,address manager,uint voteId,bool votePeriod,bool active,uint impeachIndex,uint proposalBlockNumber)= gov.cgInfo();
                if(im.impeachtype == 1){
                    gov.setManagerInfo(address(0));
                } else if(im.impeachtype == 2) {
                    gov.removeParliament(im.acceptor);
                    gov.setParliament(voteId,impeachIndex + 1);
                }
                gov.impeachExtract(address(Rbt()),im.amount * 5,im.sponsor);
            }

        }
    }

    /*
        @dev给委员会投票
    */
    function voteGovernance(IParliament gov,uint id,uint voteId,address receiver,uint tickets) public {
        _subVotes(msg.sender,voteId,tickets);
        gov.voteToParliament(id,voteId,receiver,tickets);
    }

    /*
     @dev给基金会委员会投票
 */
    function voteGovernanceFund(ICommunityGovernanceFund gov,uint voteId,address receiver,uint tickets) public {
        _subVotes(msg.sender,voteId,tickets);
        gov.voteToParliament(voteId,receiver,tickets);
    }


}

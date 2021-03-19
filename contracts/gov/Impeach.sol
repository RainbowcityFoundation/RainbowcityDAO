pragma solidity ^0.8.0;

import './CityNodeRef.sol';
import '../interface/gov/IImpeach.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../interface/gov/ICommunityGovernanceFund.sol';
import '../interface/gov/IParliament.sol';
import '../ref/VoteIdRef.sol';
import "../ref/CoreRef.sol";
import "../lib/TransferHelper.sol";
contract Impeach is CityNodeRef,IImpeach,VoteIdRef,CoreRef {
    using SafeMath for uint256;
    uint public  impeachCount;

    mapping(uint => PublicStructs.Impeach) public impeachs;

    event impeachCreate(uint indexed id,uint nodeId,address sponsor,address acceptor);
    
    
     constructor(address nodeAddress,address voteIdAddr,address core) public  CityNodeRef(nodeAddress) VoteIdRef(voteIdAddr) CoreRef(core) {}
    /*
    @dev 弹劾
    @params nodeId 节点ID
    @params type 弹劾类型1 管理 2多签
    @params user 弹劾谁
    @params amount 抵押的RBT数量
    */
    function impeach(IParliament cn,uint nodeId, uint impeachtype, address user, uint amount) external   _inNode(nodeId, msg.sender) {
        require(amount >= 100 * 10 ** 18 && amount <= 500 * 10 ** 18,'rbt amount is wrong');

        require(impeachtype == 1 || impeachtype == 2);
        (, , address manager,)= cn.getCityNodeInfo(nodeId);
        impeachCount++;
        //弹劾管理员
        if (impeachtype == 1) {
            require(manager == user, 'no this user');
        } else if (impeachtype == 2) {
            require(cn.hasParliament(nodeId,user), 'no this user');
        }
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,address(this),1000 * 10 ** 18);
        PublicStructs.Impeach storage c = impeachs[impeachCount];
        c.id = impeachCount;
        c.impeachtype = impeachtype;
        c.nodeId = nodeId;
        c.acceptor = user;
        c.sponsor = msg.sender;
        c.amount = amount;
        c.success = false;
        c.tickets = 0;
        c.voteId =  IVoteId(voteIdAddress).incrVoteId();
        c.icn = cn;
        c.creationTime = block.timestamp;
        emit impeachCreate(c.id,nodeId,msg.sender,user);
    }

    function getImpeach(uint id)  external  override  view returns(PublicStructs.Impeach memory) {
        return impeachs[id];
    }
    function setImpeachTickets(uint id,uint tickets) external override onlyVote{
        impeachs[id].tickets = impeachs[id].tickets.add(tickets);
    }
    function setImpeachSuccess(uint id) external override onlyVote{
        impeachs[id].success = true;
    }

    /*
        @dev对于四大基金会的弹劾
    */
    function impeachCommunityGovFund(ICommunityGovernanceFund gov, uint impeachtype, address user, uint amount) external  {
        require(amount >= 100 * 10 ** 18 && amount <= 500 * 10 ** 18);
        require(impeachtype == 1 || impeachtype == 2);
        (uint expireTime,address manager,uint voteId,bool votePeriod,bool active,uint impeachIndex,uint proposalBlockNumber)= gov.cgInfo();
        impeachCount++;
        //弹劾管理员
        if (impeachtype == 1) {
            require(manager == user, 'no this user');
        } else if (impeachtype == 2) {
            require(gov.hasParliament(user), 'no this user');
        }

        PublicStructs.Impeach storage c = impeachs[impeachCount];
        c.id = impeachCount;
        c.impeachtype = impeachtype;
        c.gov = gov;
        c.acceptor = user;
        c.sponsor = msg.sender;
        c.voteId =  IVoteId(voteIdAddress).incrVoteId();
        c.amount = amount;
        c.success = false;
        c.tickets = 0;
        c.creationTime = block.timestamp;
        emit impeachCreate(c.id,0,msg.sender,user);
    }

}

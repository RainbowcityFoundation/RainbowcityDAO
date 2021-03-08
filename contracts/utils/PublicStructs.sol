pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../interface/gov/ICommunityGovernanceFund.sol';
import '../interface/gov/IParliament.sol';

library PublicStructs {
  struct Impeach {
    uint id;
    uint nodeId;
    ICommunityGovernanceFund gov;
    IParliament icn;
    uint tickets;
    address acceptor; // 被弹的人
    address sponsor; //发起人
    uint creationTime;
    bool success;
    uint impeachtype;
    uint amount; //抵押的rbt数量
    uint voteId;
    // mapping(address => uint) voter; //投票人
  }

  struct parliamentApply {
    address account;
    uint tickets;
  }

}
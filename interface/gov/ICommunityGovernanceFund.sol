pragma solidity ^0.8.0;

interface ICommunityGovernanceFund {
    function voteToParliament( uint voteId, address user, uint tickets) external;
    function cgInfo() external returns(uint expireTime,address manager,uint voteId,bool votePeriod,bool active,uint impeachIndex,uint proposalBlockNumber);
    function hasParliament(address user) external  view returns (bool);
    function setManagerInfo(address manager) external;
    function removeParliament(address user) external;
    function getApplyParliamentVoteId() external view returns (uint);
    function setParliament(uint voteId, uint index) external;

    function impeachExtract(address token, uint amount, address receiver) external;

    function applyTokenExtract(address receiver, uint[] memory portion, string[] memory where, address token) external;
}

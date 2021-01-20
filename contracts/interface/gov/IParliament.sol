pragma solidity ^0.8.0;

interface IParliament {
    function hasParliament(uint nodeId, address user) external view returns (bool);

    function getCityNodeInfo(uint cityId) external view returns (bool, uint, address, uint);

    function applyParliament(uint nodeId) external;

    function voteToParliament(uint nodeId, uint voteId, address user, uint tickets) external;

    function getApplyParliament(uint nodeId, uint voteId) external view returns (uint);

    function removeParliament(uint nodeId, address user) external;

    function getApplyParliamentVoteId(uint nodeId) external view returns (uint);

    function parliamentInfo(uint nodeId) external view returns (uint, bool, uint);

    function setParliament(uint nodeId, uint voteId, uint index) external;

    function impeachExtract(uint nodeId, address token, uint amount, address receiver, uint impeach) external;

    function setManagerInfo(uint nodeId, address manager) external;

    function inNode(uint nodeId, address sender) external view returns (bool);


}

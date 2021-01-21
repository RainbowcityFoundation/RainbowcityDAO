pragma solidity ^0.8.0;

interface ICityNode {

    function joinNode(uint nodeId) external;

    function createNode(uint tokenId,string memory name, bytes32  hash,uint c,uint a) external;

    // function getCityNodeInfo(uint cityId) external view returns (bool, uint, address, uint);

    function getExistsApplyUsers(uint nodeId, uint voteId, address applicant) external view returns (bool);

    function voteToManager(uint nodeId, uint voteId, address user, uint tickets) external;

    function endToManager(uint nodeId, uint voteId) external;

    function existsCityNode(uint nodeId) external view returns (bool);


    function quitNode() external;

    function lengthen(uint nodeId,uint tokenId) external;

    function activeToCampaign(uint nodeId) external;

    function applyManager(uint nodeId, uint tokenId) external;

    function endToParliament(uint nodeId, uint voteId) external;

    function getUserNode(address sender) external view  returns(uint);
    function getNodeCityGov(uint nodeId) external  view returns(uint);
    function getCityTrueId(uint id) external  view returns(uint);
}

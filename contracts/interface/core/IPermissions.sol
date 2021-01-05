// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface IPermissions {
   

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;
   
    function revokeGovernor(address governor) external;
    function revokeOverride(bytes32 role, address account) external;
   

    function isGovernor(address _address) external view returns (bool);

    function isCityNode(address _address) external view returns (bool);
    
    function grantCityNode(address cityNode) external;
    function revokeCityNode(address cityNode) external;

    function isVote(address _address) external view  returns (bool);
    function grantVote(address vote) external;
    function revokeVote(address vote) external;

}

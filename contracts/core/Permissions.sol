// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interface/core/IPermissions.sol";


/// @title Access control module for Core
/// @author Rainbow
contract Permissions is IPermissions, AccessControl {

    //总管理员
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant CITY_NODE_ROLE = keccak256("CITY_NODE_ROLE");
    bytes32 public constant VOTE_ROLE = keccak256("VOTE_ROLE");

    constructor() public {

        _setupGovernor(address(this));
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(CITY_NODE_ROLE, GOVERN_ROLE);
        _setRoleAdmin(VOTE_ROLE, GOVERN_ROLE);

    }
    modifier onlyGovernor() {
        require(
            isGovernor(msg.sender),
            "Permissions: Caller is not a governor"
        );
        _;
    }
    function isVote(address _address) external view override returns (bool)
    {
        return hasRole(VOTE_ROLE, _address);
    }

    function grantVote(address vote) external override onlyGovernor
    {
        grantRole(VOTE_ROLE, vote);
    }

    function revokeVote(address vote) external override onlyGovernor
    {
        revokeRole(VOTE_ROLE, vote);
    }



    function isCityNode(address _address) external view override returns (bool)
    {
        return hasRole(CITY_NODE_ROLE, _address);
    }

    function grantCityNode(address cityNode) external override onlyGovernor
    {
        grantRole(CITY_NODE_ROLE, cityNode);
    }

    function revokeCityNode(address cityNode) external override onlyGovernor
    {
        revokeRole(CITY_NODE_ROLE, cityNode);
    }

    function grantGovernor(address governor) external override onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function revokeGovernor(address governor) external override onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }

    function createRole(bytes32 role, bytes32 adminRole) external override onlyGovernor {
        _setRoleAdmin(role, adminRole);
    }

    function revokeOverride(bytes32 role, address account) external override {
        require(role != GOVERN_ROLE, "Permissions: Guardian cannot revoke governor");
        this.revokeRole(role, account);
    }

    function isGovernor(address _address) public view virtual override returns (bool) {
        return hasRole(GOVERN_ROLE, _address);
    }

}

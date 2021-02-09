pragma solidity ^0.8.0;

import "../lib/TransferHelper.sol";

import "../ref/CommunityGovernanceFundRef.sol";
contract RBTCommunityInvestmentFund is CommunityGovernanceFundRef{
    constructor(address core,address voteIdAddr)   CommunityGovernanceFundRef(core,voteIdAddr)  {}

    function active() public {
        require(cgInfo.active == false,'already active');
        IERC20 rbt = core().rbt();
        uint balance = rbt.balanceOf(address(this));
        require(balance >= 3000000 * 10 ** 18 ,'not enough rbt');
        cgInfo.impeachIndex = 12;
        cgInfo.active = true;
    }
}

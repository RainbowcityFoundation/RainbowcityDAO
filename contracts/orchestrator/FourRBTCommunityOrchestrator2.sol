// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";



import "../gov/RBTCommunityInvestmentFund.sol";
import "../gov/RBTCommunityRewardFund.sol";


contract FourRBTCommunityOrchestrator2 is Initializable  {


    address public RBTCommunityInvestmentFundAddr;
    address public RBTCommunityRewardFundAddr;

    function init(address core,address voteIdAddr) external initializer {

        RBTCommunityInvestmentFundAddr = address(new RBTCommunityInvestmentFund(core,voteIdAddr));
        RBTCommunityRewardFundAddr = address(new RBTCommunityRewardFund(core,voteIdAddr));
    }
}
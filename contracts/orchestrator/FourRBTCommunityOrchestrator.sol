// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


import "../gov/RBTCommunityCharitableFund.sol";
import "../gov/RBTCommunityGovernanceFund.sol";



contract FourRBTCommunityOrchestrator is Initializable  {

    address public RBTCommunityCharitableFundAddr;
    address public RBTCommunityGovernanceFundAddr;


    function init(address core,address voteIdAddr) external initializer {
        RBTCommunityCharitableFundAddr = address(new RBTCommunityCharitableFund(core,voteIdAddr));
        RBTCommunityGovernanceFundAddr = address(new RBTCommunityGovernanceFund(core,voteIdAddr));

    }
}
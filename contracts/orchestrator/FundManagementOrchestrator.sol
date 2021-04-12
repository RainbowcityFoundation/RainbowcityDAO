// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


import "../gov/FundManagement.sol";


contract FundManagementOrchestrator is Initializable  {

    address public FundManagementAddr;

    function init(address core,address voteIdAddr) external initializer {
        FundManagementAddr = address(new FundManagement(core,voteIdAddr));
    }
}
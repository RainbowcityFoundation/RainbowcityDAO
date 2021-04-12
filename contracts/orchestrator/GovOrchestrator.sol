// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


import "../gov/CityNode.sol";
import "../gov/VoteId.sol";


contract GovOrchestrator is Initializable  {

    address public cityNode;
    address public voteId;

    function init(address core) external initializer {

        voteId = address(new VoteId());

        cityNode = address(new CityNode(core,voteId));
    }
}
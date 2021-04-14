// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";



import "../gov/Impeach.sol";
import "../gov/Vote.sol";

contract GovOrchestrator2 is Initializable  {

    address public impeach;
    address public vote;

    function init(address core,address cityNode,address voteId) external initializer {

        impeach = address(new Impeach(cityNode,voteId,core));

        vote = address(new Vote(cityNode,core));
    }
}
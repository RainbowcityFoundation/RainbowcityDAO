// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../RainbowVote/RainbowRbtVote.sol";

contract RbtVoteOrchestrator  is Ownable {
    address public voteAddress;
    function init(
        address rbVip,
        address core
    )
        public
        onlyOwner
        
    {
        voteAddress = address(
            new RainbowRbtVote(rbVip,core)
        );
    }

}
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../mining/RbConsensus.sol";

contract RbConsensusOrchestrator is Ownable {
    address public rbConsersusAddress;

    function init(
        address RBT,
        address VIP
    ) public
    onlyOwner
    returns (address rbConsersus)
    {
        rbConsersusAddress = address(
            new RbConsensus(RBT,address(0), VIP, msg.sender)

        );
    }
}
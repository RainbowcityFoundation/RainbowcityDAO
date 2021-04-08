pragma solidity =0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../mining/RbContribution.sol";

contract RbContributionOrchestrator is Ownable {
    address public rbcontributionAddress;

    function init(
        address RBD, address RBT
    ) public
    onlyOwner
    returns (address rbcontribution)
    {
        rbcontributionAddress = address(
            new RbContribution(RBD, RBT, address(0), msg.sender)

        );

    }
}
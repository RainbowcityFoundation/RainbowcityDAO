pragma solidity =0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../mining/RbSeedSubscription.sol";

contract RbSeedSubscriptionOrchestrator is Ownable {
    address public RbSeedSubscriptionAddress;

    function init(
        address seed
    ) public
    onlyOwner
    returns (address rbseedsubscription)
    {
        RbSeedSubscriptionAddress = address(
            new RbSeedSubscription(seed,msg.sender)

        );

    }
}
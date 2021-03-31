pragma solidity =0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../mining/RbSeedExchange.sol";

contract RbSeedExchangeOrchestrator is Ownable {
    address public rbSeedExchangeAddress;

    function init(
        address RBT_SEED, address RBT
    ) public
    onlyOwner
    returns (address rbSeedExchanges)
    {
        rbSeedExchangeAddress = address(
            new RbSeedExchange(RBT_SEED, RBT,msg.sender)

        );

    }
}
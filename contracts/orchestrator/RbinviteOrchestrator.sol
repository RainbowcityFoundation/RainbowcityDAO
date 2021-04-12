pragma solidity =0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../mining/Rbinvite.sol";

contract RbinviteOrchestrator is Ownable {
    address public rbinviteAddress;

    function init(
        address RBTEX, address RBT, address RBCONSENSUS
    ) public
    onlyOwner
    returns (address rbinvite)
    {
        rbinviteAddress = address(
            new Rbinvite(RBTEX, RBT, RBCONSENSUS,msg.sender)

        );

    }
}
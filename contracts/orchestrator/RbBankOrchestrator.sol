pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../RainbowBank/RainbowBank.sol";
contract RbBankOrchestrator is  Ownable{
    address  public bank;
    function init(address core)public  onlyOwner{
        bank=address(new RainbowBank(core));
    }
     function  input(address _rbt,address _deposits) public{
         RainbowBank(bank).init(_rbt, _deposits);
    }
    function detonate() public  onlyOwner {
        selfdestruct(payable(owner()));
    }
}

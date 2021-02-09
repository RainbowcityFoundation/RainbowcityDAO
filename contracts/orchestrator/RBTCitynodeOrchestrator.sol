pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../token721/RBTCitynode.sol";
import "../ExchangeGovernance721.sol";

contract RBTCitynodeOrchestrator is  Ownable{

    address public rbtCitynode;

    function init(address core,address _exchangeGovernance721 ) public  onlyOwner{
        rbtCitynode=address(new RBTCitynode(core ,_exchangeGovernance721, "citynode" ));
                          
    }
    
    function detonate() public  onlyOwner {
        selfdestruct(payable(owner()));
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token721/RbtDeposit721.sol";
import "../token721/Governance721.sol";
import "../ExchangeGovernance721.sol";
import "../token721/RBTCitynode.sol";

contract ExchangeGovernance721Orchestrator is  Ownable{
    address public deposit;
    address public elf;
    address public envoy;
    address public partner;
    address public node;
    address public exchangeGovernance721;
    address public rbtCitynode;
    
    function init(address core,address _deposit) public  onlyOwner{
        deposit=_deposit;
        exchangeGovernance721 =address(new ExchangeGovernance721(core));
        elf= address(new Governance721(core,exchangeGovernance721,"RbtElf")); 
        envoy= address(new Governance721(core,exchangeGovernance721,"RbtEnvoy"));
        partner= address(new Governance721(core,exchangeGovernance721,"RbtPartner"));
        node= address(new Governance721(core,exchangeGovernance721,"RbtNode"));  
        ExchangeGovernance721(exchangeGovernance721).init(deposit,elf,envoy,partner,node);  
        
              
    }
    function initCitynode(address _citynode)public onlyOwner{
        rbtCitynode=_citynode;
        ExchangeGovernance721(exchangeGovernance721).initCitynode(rbtCitynode);

    }
    
    function detonate() public  onlyOwner {
        selfdestruct(payable(owner()));
    }
    
}
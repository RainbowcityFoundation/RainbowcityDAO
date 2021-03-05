// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../RainbowBank/market721/TokenExchangeMarket.sol";

contract TokenExchangeMarketOrchestrator is  Ownable{
    address public tokenExchange;
    address public agent;
    function init(address core,address rbt,address elf ,address envoy,address  partner,address  node) public  onlyOwner{
      tokenExchange=address(new TokenExchangeMarket(core));
      TokenExchangeMarket(tokenExchange).init(agent,rbt,elf,envoy,partner,node);
    }
    function detonate() public  onlyOwner {
      selfdestruct(payable(owner()));
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../RainbowVip/RainbowRbtVip.sol";

contract RbtVipOrchestrator  is Ownable {
    address public vipAddress;
    function init(
        uint price,
        address foundationAddress,
        address rbtex,
        address core
    )
        public
        onlyOwner
        
    {
        vipAddress = address(
            new RainbowRbtVip(price,foundationAddress,rbtex,core)
        );
    }

    function detonate() public onlyOwner {
        selfdestruct(payable(owner()));
    }
}
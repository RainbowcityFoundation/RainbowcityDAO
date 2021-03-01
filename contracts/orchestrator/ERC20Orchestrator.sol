// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../token20/RBT.sol";
import "../token20/RBTEX.sol";
import "../token20/RBTSeed.sol";
import "../token20/RBD.sol";

contract ERC20Orchestrator is Initializable {

    address public rbt;
    address public rbd;
    address public rbtex;
    address public rbtseed;

    function init(address manager,address ecologyIncome) external initializer {

        rbt = address(new RBT(manager,ecologyIncome));

        rbd = address(new RBD(manager));
      
        rbtex = address(new RBTEX(manager));

        rbtseed = address(new RBTSeed(manager));
    }
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../token20/RBTC.sol";
import "../token20/RBB.sol";
import "../token20/RUSD.sol";

contract ERC20Orchestrator2 is Initializable {

    address public rbb;
    address public rusd;
    address public rbtc;

    function init(address manager) external initializer {

        rbb = address(new RBB(manager));

        rusd = address(new RUSD(manager));

        rbtc = address(new RBTC(manager));

    }

}
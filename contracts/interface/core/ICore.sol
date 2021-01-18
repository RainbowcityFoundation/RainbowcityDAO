// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IPermissions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICore is IPermissions {
    event RBTUpdate(address indexed _rbt);
    event RBBUpdate(address indexed _rbb);
    event RUSDUpdate(address indexed _rusd);
    event RBTCUpdate(address indexed _rbtc);
    event RBDUpdate(address indexed _rbd);
    event RBTEXUpdate(address indexed _rbtex);
    event RBTSeedUpdate(address indexed _rbtseed);
    
 
    
    function setRBT(address token) external;
    function setRBB(address token) external;
    function setRUSD(address token) external;
    function setRBTC(address token) external;
    function setRBD(address token) external;
    function setRBTEX(address token) external;
    function setRBTSeed(address token) external;
    function rbt() external view returns(IERC20);
}

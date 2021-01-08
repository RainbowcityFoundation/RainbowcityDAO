// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Permissions.sol";
import "../interface/core/ICore.sol";

contract Core is ICore, Permissions {
    
    IERC20 public override rbt;
    IERC20 public rbb;
    IERC20 public rusd;
    IERC20 public rbtc;
    IERC20 public rbd;
    IERC20 public rbtex;
    IERC20 public rbtseed;
    
    constructor(address manager) public {
        
        _setupGovernor(manager);
        
    }
    
    function setRBT(address token) external override onlyGovernor {
        rbt = IERC20(token);
        emit RBTUpdate(token);
    }

    function setRBB(address token) external override onlyGovernor {
        rbb = IERC20(token);
        emit RBBUpdate(token);
    }
    function setRUSD(address token) external override onlyGovernor {
         rusd = IERC20(token);
        emit RUSDUpdate(token);
    }
    function setRBTC(address token) external override onlyGovernor  {
        rbtc = IERC20(token);
        emit RBTCUpdate(token);
    }
    function setRBD(address token) external override onlyGovernor {
        rbd = IERC20(token);
        emit RBDUpdate(token);
    }
    function setRBTEX(address token) external override onlyGovernor {
        rbtex = IERC20(token);
        emit RBTEXUpdate(token);
    }
    function setRBTSeed(address token) external override onlyGovernor {
        rbtseed = IERC20(token);
        emit RBTSeedUpdate(token);
    }
    
}

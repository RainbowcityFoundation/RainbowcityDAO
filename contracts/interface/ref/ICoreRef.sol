// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../core/ICore.sol";


interface ICoreRef {
   
    event CoreUpdate(address indexed _core);

   
    function setCore(address core) external;
    function core() external view returns (ICore);
     function Rbt() external view  returns (IERC20);
    
}
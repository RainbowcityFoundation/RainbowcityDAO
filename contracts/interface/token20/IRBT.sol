// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRBT is IERC20{
    function modifyFee(uint value) external ;
    function addFreeUser(address userAddress) external;
    function removeFreeUser(address userAddress) external;
    
}
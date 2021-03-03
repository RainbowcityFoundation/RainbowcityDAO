// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoteOracle{
    
 function  getPriorVotes(address account, uint blockNumber) external  view returns (uint256);

 function getCurrentVotes(address account) external view returns (uint96);

}
pragma solidity ^0.8.0;

interface IBlockNumber {
    function getBlockNumber(uint id) external view returns(uint);
}

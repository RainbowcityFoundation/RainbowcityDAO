pragma solidity =0.8.0;

interface IRbConsensus {
    function getRbtPrice() external view returns(uint);
    function exchangeRatio(address addr) external view returns(uint,uint);
}
pragma solidity ^0.8.0;

interface ICityNodeFundManagement {
    function addTokenStorage(string memory store, address token, uint amount) external;
    function getUserReward(address user,address token) external view returns(uint);
    function setUserReward(address user ,address token ,uint amount,uint operate) external;
    function impeachTokenSend(address receiver,uint amount,address token,uint impeachtype) external;
}

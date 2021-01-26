pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../token721/RbtDeposit721.sol";


contract DepositIncome {
    
    address public admin;
    address public RbtDeposit721Address;
    mapping (uint=> uint256) power;
    
    
    constructor(address manager,address _RbtDeposit721Address)  public {
        admin = manager;
        RbtDeposit721Address = _RbtDeposit721Address;
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    
    function changeOwner(address manager) external _isOwner {
        admin = manager;
    }
    
    function getPower(uint datetimes) public returns (uint){
        
        RbtDeposit721 rbtDeposit721 =RbtDeposit721(RbtDeposit721Address);
        uint256 a = rbtDeposit721.balanceOf(msg.sender);
        uint256 i=0;
        uint256 amount2=0;
        
        while(i<a){
            uint256 tokenId = rbtDeposit721.tokenOfOwnerByIndex(msg.sender,i);
            // Deposit memory deposit = rbtDeposit721.tokenMetadata(tokenId);
            uint256 startTime= rbtDeposit721.tokenMetadata(tokenId).startTime;
            uint256 expireTime= rbtDeposit721.tokenMetadata(tokenId).expireTime;
            if (block.timestamp <= expireTime && expireTime-startTime == datetimes){
                amount2 += rbtDeposit721.tokenMetadata(tokenId).amount;
            }
            i++;
        }
        uint256 amount = amount2 * power[datetimes];
        return amount;
    }
    
}
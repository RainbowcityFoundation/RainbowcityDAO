// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FoundationToken {
    using SafeMath for uint;

    address private RbtToken;
    address public admin;
    uint public RBTBonusAmount;
    uint public ConsensusBonusAmount;

    mapping(address => bool) public ifExsit; //token地址是否存在 
    address[] public tokens;         //代币地址 
    event IncomeAllot(address indexed to, uint256 amount,uint indexed timestamp,address indexed token);
    
    constructor(address manager)  public {
        admin = manager;
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    
    function changeOwner(address manager) external _isOwner {
        admin = manager;
        
    }
    
    function addRBTBonusAmount(uint amount) public{
        RBTBonusAmount = RBTBonusAmount.add(amount);
    }

    function addConsensusBonusAmount(uint amount) public{
        ConsensusBonusAmount = ConsensusBonusAmount.add(amount);
    }
    
    
    function addToken(address ercToken) public {
        require(ifExsit[ercToken] != true ,"Exsited");
        ifExsit[ercToken]=true;
        tokens.push(ercToken);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RBB is ERC20{
    address public admin;
    event AdminChange(address indexed Admin, address indexed newAdmin);
    constructor(address manager) public ERC20("Rainbow Bond", "RBB") {
       admin = manager;
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    
    function changeOwner(address manager) external _isOwner {
        admin = manager;
        emit AdminChange(msg.sender,manager);
    }
    function mint(address account, uint256 amount) external _isOwner {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) external _isOwner{
        _burn(account, amount);
    }
}
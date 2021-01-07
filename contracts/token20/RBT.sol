// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interface/token20/IRBT.sol";

contract RBT is ERC20{
    using SafeMath for uint256;
    //管理者
    address public admin;
    //收税人
    address public feeto;
    
    //税率 s
    uint public fee = 30;
    //免税名单
    mapping(address => bool) public freeUsers;
    
    event AdminChange(address indexed Admin, address indexed newAdmin);
    event FreeUserChange(address indexed userAddress, bool indexed flag);
    constructor(address manager)  public ERC20("Rainbow Token","RBT"){
        admin = manager;
        feeto = manager;
        _mint(manager, 5000_000_000 * 10 ** 18);
        
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    /**
    * @notice 设置管理者 
    * @param manager 管理者
    */
    function changeOwner(address manager) external _isOwner {
        admin = manager;
        emit AdminChange(msg.sender,manager);
    }
    /**
    * @notice 设置税率
    * @param value 税率
    */
    function modifyFee(uint value) external _isOwner {
        fee = value;
    }
    /**
    * @notice 设置收税人
    * @param guager 收税人
    */
    function changeFeeTo(address guager) external _isOwner {
        feeto = guager;
    }
    /**
    * @notice 添加到免税名单
    * @param userAddress 要添加的地址
    */
    function addFreeUser(address userAddress) public _isOwner {
        freeUsers[userAddress] = true;
        emit FreeUserChange(userAddress,true);
    }
    /**
    * @notice 从免税名单移除
    * @param userAddress 要移除的地址
    */
    function removeFreeUser(address userAddress) public _isOwner {
        freeUsers[userAddress] = false;
        emit FreeUserChange(userAddress,false);
    }
    
    /**
    * @notice 燃烧
    * @param account 燃烧的账户
    * @param amount 燃耗数额
    */
    function burn(address account, uint256 amount) external _isOwner{
        _burn(account, amount);
    }
    /**
    * @notice 转账
    * @param recipient 接受人
    * @param amount 转账数额
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       
        _transferRBT(msg.sender,recipient,amount);
        return true;
    }
    
    
    /**
    * @notice 授权转账
    * @param sender 发送人
    * @param recipient 接受人
    * @param amount 转账数额
    */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        
        _transferRBT(sender,recipient,amount);
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance-amount);
        return true;
    }
    
     /**
    * @notice 转账
    * @param sender 发送人
    * @param recipient 接受人
    * @param amount 转账数额
    */
    function _transferRBT(address sender, address recipient, uint256 amount) internal {
          
        
         if (freeUsers[sender] == true) {
            _transfer(sender, recipient, amount);
            
        } else {
            uint256 aa = 10000;
            uint256 amount1 = amount.mul(aa.sub(fee)).div(aa);
            _transfer(sender, recipient, amount1);
            uint256 amount2 = amount.mul(fee).div(aa);
            _transfer(sender, feeto, amount2);
            
            
        }
        
        
    }
    
    
}

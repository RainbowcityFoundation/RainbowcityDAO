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
    //存储着某个区块的票数
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    //存储某个地址在某次改动的区块号和票数
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    //存储某个地址发生了几次改动
    mapping (address => uint32) public numCheckpoints;
    
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    event FreeUserChange(address indexed userAddress, bool indexed flag);
    constructor(address manager)  public ERC20("Rainbow Token","RBT"){
        admin = manager;
        feeto = manager;
        _mint(manager, 5000_000_000 * 10 ** 18);
        
        _addDelegates(manager, safe96(5000_000_000 * 10 ** 18,"RBT: vote amount underflows"));
    
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
    * @notice 获取当前票数
    * @param account 要查绚的地址
    */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    /**
    * @notice 获取某区块票数
    * @param account 要查绚的地址
    * @param blockNumber 要查绚的区块
    */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
         require(blockNumber <= block.number, "RBT: not yet determined");
    
         uint32 nCheckpoints = numCheckpoints[account];
         if (nCheckpoints == 0 || checkpoints[account][0].fromBlock > blockNumber) {
             return 0;
         }
         
         if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
             return checkpoints[account][nCheckpoints - 1].votes;
         }
    //存储某个地址在某次改动的区块号和票数
    // mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    //存储某个地址发生了几次改动
    // mapping (address => uint32) public numCheckpoints;
         uint32 lower = 0;
         uint32 upper = nCheckpoints - 1;
         while (upper > lower) {
             uint32 center = upper - (upper - lower) / 2; 
             Checkpoint memory cp = checkpoints[account][center];
             if (cp.fromBlock == blockNumber) {
                 return cp.votes;
             } else if (cp.fromBlock < blockNumber) {
                 lower = center;
             } else {
                 upper = center - 1;
             }
        }
        return checkpoints[account][lower].votes;
     }
     /**
    * @notice 转账
    * @param sender 发送人
    * @param recipient 接受人
    * @param amount 转账数额
    */
    function _transferRBT(address sender, address recipient, uint256 amount) internal {
          
        uint96 amount96 = safe96(amount,"vote: vote amount underflows");
         if (freeUsers[sender] == true) {
            _transfer(sender, recipient, amount);
            _addDelegates(recipient, amount96);
        } else {
            uint256 aa = 10000;
            uint256 amount1 = amount.mul(aa.sub(fee)).div(aa);
            _transfer(sender, recipient, amount1);
            uint256 amount2 = amount.mul(fee).div(aa);
            _transfer(sender, feeto, amount2);
            uint96 vote96 = safe96(amount1,"vote: vote amount underflows");
            uint96 fee96 = safe96(amount2,"vote: vote amount underflows");
            _addDelegates(recipient, vote96);
            _addDelegates(feeto, fee96);
            
        }
        
        _devDelegates(sender, amount96);
    }
    /**
    * @notice 添加票数
    * @param dstRep 要添加票数的地址
    * @param amount 要添加票数的数量
    */
    function _addDelegates(address dstRep, uint96 amount) internal {
          
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "RBT: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        
    }
    /**
    * @notice 减少票数
    * @param srcRep 要减少票数的地址
    * @param amount 要减少票数的数量
    */
    function _devDelegates(address srcRep,  uint96 amount) internal {
          
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "RBT: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
    }
    /**
    * @notice 更改票数
    * @param delegatee 要更改票数的地址
    * @param nCheckpoints 票数改变的次数
    * @param oldVotes 旧的票数
    * @param newVotes 新的票数
    */
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "RBT: block number exceeds 32 bits");
    
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
    
    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }
    
}

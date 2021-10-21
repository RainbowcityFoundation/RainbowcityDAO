// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interface/token20/IRBT.sol";
import "../income/EcologyIncome.sol";

contract RBT is ERC20{
    using SafeMath for uint256;
    //administrator 
    address public admin;
    //The tax man 
    address public feeto;
    
    //Rate
    uint public fee = 30;
    EcologyIncome public ecologyIncomecont;
    //tax-exempt list
    mapping(address => bool) public freeUsers;
    //A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }
    //A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;
    
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    event FeetoChange(address indexed feeto, address indexed newFeeto);
    event FreeUserChange(address indexed userAddress, bool indexed flag);
    constructor(address manager,address _ecologyIncome)  public ERC20("Rainbow Token","RBT"){
        admin = manager;
        feeto = manager;
        ecologyIncomecont=EcologyIncome(_ecologyIncome);
        _mint(manager, 5000_000_000 * 10 ** 18);
        
        _addDelegates(manager, safe96(5000_000_000 * 10 ** 18,"RBT: vote amount underflows"));
        
    }
    
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    /**
    * @notice Setup the manager 
    * @param manager the manager
    */
    function changeOwner(address manager) external _isOwner {
        admin = manager;
        emit AdminChange(msg.sender,manager);
    }
    /**
    * @notice Set the rate
    * @param value the rate
    */
    function modifyFee(uint value) external _isOwner {
        fee = value;
    }
    /**
    * @notice Set the tax man 
    * @param guager tax man 
    */
    function changeFeeTo(address guager) external _isOwner {
        feeto = guager;
        emit FeetoChange(msg.sender,guager);
    }
    /**
    * @notice Add to the tax-exempt list
    * @param userAddress The address to add
    */
    function addFreeUser(address userAddress) public _isOwner {
        freeUsers[userAddress] = true;
        emit FreeUserChange(userAddress,true);
    }
    /**
    * @notice Removed from the tax-exempt list
    * @param userAddress The address to remove
    */
    function removeFreeUser(address userAddress) public _isOwner {
        freeUsers[userAddress] = false;
        emit FreeUserChange(userAddress,false);
    }
    
    /**
    * @notice Destroys `amount` tokens from `account`, reducing the
    * total supply.
    * @param account Burning account
    * @param amount The amount of fuel
    */
    function burn(address account, uint256 amount) external _isOwner{
        _burn(account, amount);
    }
    /**
    * @notice Moves `amount` tokens from the caller's account to `recipient`.
    * @param recipient Accept people
    * @param amount Amount to be transferred
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       
       
        _transferRBT(msg.sender,recipient,amount);
        return true;
        
    }
    
    
    /**
    * @notice Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's allowance.
    * @param sender The sender
    * @param recipient Accept people
    * @param amount Amount to be transferred
    * @return Whether or not the transfer succeeded
    */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        
        _transferRBT(sender,recipient,amount);
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance-amount);
        return true;
    }
    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }
    
    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
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
    * @notice Moves tokens `amount` from `sender` to `recipient`.
    * @param sender The sender
    * @param recipient Accept people
    * @param amount Amount to be transferred
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
            
            uint32 a = 11;
            ecologyIncomecont.receivew(a,address(this));
        }
        
        _devDelegates(sender, amount96);
    }
     /**
    * @notice Add the votes
    * @param dstRep The address to which the ticket is to be added
    * @param amount The number of votes to add
    */
    function _addDelegates(address dstRep, uint96 amount) internal {
          
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "RBT: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        
    }
    /**
    * @notice Remove the votes
    * @param srcRep The address to which the ticket is to be removed
    * @param amount The number of votes to remove
    */
    function _devDelegates(address srcRep,  uint96 amount) internal {
          
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "RBT: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
    }
    /**
    * @notice Change the number
    * @param delegatee To change the address of the vote
    * @param nCheckpoints The number of times the vote was changed
    * @param oldVotes The old number
    * @param newVotes The new number
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

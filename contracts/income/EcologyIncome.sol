// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


import "../interface/IRbtVip.sol";
import {userVipStruct} from '../lib/userVipStruct.sol';

contract EcologyIncome is Initializable {
    using SafeMath for uint256;
    mapping(address =>uint256) receive1;
    
    uint32 aa = 9;
    IRbtVip public rbtvip;
    //收税人
    // address public feeto;
    //管理者
    address public admin;
    
    //存储着某个区块的数量 
    struct Checkpoint {
        uint32 fromBlock;
        uint256 amount;
    }
    mapping(address => bool) public ifExsit; //token地址是否存在 
    address[] public tokens;         //代币地址 
    
    mapping(address =>mapping(address => mapping(uint32 => mapping (uint32 => Checkpoint))))receive2;
    //每个人
    mapping(address => mapping(address => mapping(uint32 =>uint256))) receive3;
    
    mapping(address => uint8) scale;
    
    //存储某个地址发生了几次改动
    mapping(address =>mapping(address =>mapping (uint32 => uint32))) public numCheckpoints;
    
    event UserReceiveChanged(address indexed useraddress, address indexed tokenadderss, uint32 indexed source,uint amount);
    event AdminChange(address indexed Admin, address indexed newAdmin);
    event ReceiveChanged( address indexed tokenadderss, uint32 indexed source,uint amount);
    
    constructor(address manager)  public {
        
        admin = manager;
        
    }
    function init(address _rbtvip) external initializer {
        rbtvip = IRbtVip(_rbtvip);
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
    function receivew(uint32 source,address tokenadderss) public returns (bool){
        uint256 balance =IERC20(tokenadderss).balanceOf(address (this)); //TODO
        
        uint256 amount = balance - receive1[tokenadderss];
        uint256 ratio = 50;
        uint32 blockNumber = safe32( block.number,"EcologyIncome: block number exceeds 32 bits");
        uint32 nCheckpoints = numCheckpoints[msg.sender][tokenadderss][source];
        
        _writereceive(msg.sender, source, nCheckpoints, tokenadderss, amount);
        userVipStruct.User memory a = rbtvip.getUserInfo(msg.sender);
        address referUser = a.addrRef;
        if(referUser == address(0)){
            ratio += 20;
        }else{
            userVipStruct.User memory b = rbtvip.getUserInfo(referUser);
            
            if( b.addrRef == address(0)){
                ratio += 4;
            }
        }
        
        receive1[tokenadderss] += amount;
        uint256 amount2 = amount * ratio / 100;
        receive3[address(this)][tokenadderss][source] += amount2;
        emit ReceiveChanged( tokenadderss, source,amount);
        return true;
    }
     function received(address tokenadderss) public view returns (uint){
        
        return receive1[tokenadderss] ;
        
    }
    
    function examineRbt(address from, address tokenadderss,uint32 source,uint256 amount) public {
        receive3[from][tokenadderss][source] +=amount;//TODO
    }
    
    function _writereceive(address useraddress,uint32 source, uint32 nCheckpoints,address tokenadderss, uint256 amount) internal {
        uint32 dstRepNum = numCheckpoints[useraddress][tokenadderss][source];
        uint256 oldAmounts = dstRepNum > 0 ? receive2[useraddress][tokenadderss][source][dstRepNum - 1].amount : 0;
        uint256 newAmounts = oldAmounts.add(amount);
        uint32 blockNumber = safe32(block.number, "RBT: block number exceeds 32 bits");
        
        if (nCheckpoints > 0 && receive2[useraddress][tokenadderss][source][nCheckpoints - 1].fromBlock == blockNumber) {
            receive2[useraddress][tokenadderss][source][nCheckpoints - 1].amount = newAmounts;
        } else {
            receive2[useraddress][tokenadderss][source][nCheckpoints] = Checkpoint(blockNumber, newAmounts);
            numCheckpoints[useraddress][tokenadderss][source] = nCheckpoints + 1;
        }
    
        emit UserReceiveChanged(useraddress,tokenadderss,source, amount);
    }
     

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
    
}
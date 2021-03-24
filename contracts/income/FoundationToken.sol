// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/BoringERC20.sol";
import '../lib/TransferHelper.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FoundationToken {
    using SafeMath for uint;

    address private RbtToken;
    address public admin;
    uint public RBTBonusAmount;
    uint public ConsensusBonusAmount;
    address public ManageTeam;
    address public RbtCommunityTeam;
    address public CycleLockIncome;
    address public CommunityLockIncome;
    address public ZoologyAwardFund;
    address public ZoologyHatchFund;
    address public ZoologyCharityFund;
    address public SecondaryMarket;
    address public RainMasterFund;

    mapping(address => bool) public ifExsit; //token地址是否存在 
    address[] public tokens;         //代币地址 
    event IncomeAllot(address indexed to, uint256 amount,uint indexed timestamp,address indexed token);
    
    constructor(address manager,address _manageTeam,address _rbtCommunityTeam,address _cycleLockIncome,address _communityLockIncome,
    address _zoologyAwardFund,address _zoologyHatchFund,address _zoologyCharityFund,address _secondaryMarket,address _rainMasterFund)  public {
        admin = manager;
        ManageTeam = _manageTeam;
        RbtCommunityTeam = _rbtCommunityTeam;
        CycleLockIncome = _cycleLockIncome;
        CommunityLockIncome = _communityLockIncome;
        ZoologyAwardFund =_zoologyAwardFund ;
        ZoologyHatchFund = _zoologyHatchFund;
        ZoologyCharityFund = _zoologyCharityFund;
        SecondaryMarket = _secondaryMarket;
        RainMasterFund = _rainMasterFund;
    }
    modifier  _isOwner() {
        require(msg.sender == admin);
        _;
    }
    
    function changeOwner(address manager) external _isOwner {
        admin = manager;
        // emit AdminChange(msg.sender,manager);
    }
    
    function addRBTBonusAmount(uint amount) public{
        RBTBonusAmount = RBTBonusAmount.add(amount);
    }

    function addConsensusBonusAmount(uint amount) public{
        ConsensusBonusAmount = ConsensusBonusAmount.add(amount);
    }
    //  分配
    function incomeAllot() public {
        // RbtToken = Cr.getContract("RBT");
        require(IERC20(RbtToken).balanceOf(address(this))>0,"The amount is insufficient");
        //分配总数
        uint256 totalNum=IERC20(RbtToken).balanceOf(address(this)).mul(4).div(5);
        TransferHelper.safeTransfer(RbtToken, ManageTeam, totalNum.div(5));
        TransferHelper.safeTransfer(RbtToken, RbtCommunityTeam, totalNum.div(5));
        TransferHelper.safeTransfer(RbtToken, CycleLockIncome, totalNum.div(5));
        TransferHelper.safeTransfer(RbtToken, CommunityLockIncome, totalNum.div(5));
        TransferHelper.safeTransfer(RbtToken, ZoologyAwardFund, totalNum.div(20));
        TransferHelper.safeTransfer(RbtToken, ZoologyHatchFund, totalNum.div(20));
        TransferHelper.safeTransfer(RbtToken, ZoologyCharityFund, totalNum.div(20));
        TransferHelper.safeTransfer(RbtToken, SecondaryMarket, totalNum.div(20));
        TransferHelper.safeTransfer(RbtToken, RainMasterFund,totalNum.div(5));

    }
    
    function addToken(address ercToken) public {
        require(ifExsit[ercToken] != true ,"Exsited");
        ifExsit[ercToken]=true;
        tokens.push(ercToken);
    }
}
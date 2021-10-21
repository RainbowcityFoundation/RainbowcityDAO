pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "../interface/bank/IRbBank.sol";

abstract contract MiningBase {
    using SafeMath for uint;//The security library
    address public _Rbt;//RBT address
    address public _bank_Address;//bank address
    address public admin;//Administrator address
    uint public _lockTime = 365 days;//Lock up time
    mapping(address => uint) public userTotalReceived;//Get the total withdrawal of the contract

    struct Record {
        uint startTime;//Lockup start time
        uint endTime;//Full release time
        uint amount;//Amount of RBT tokens exchanged
        uint extracted;//Already extracted
        uint price;//Set trading price
        uint mortgage;//The pledge number

    }

    //Setting an Administrator address
    modifier onlyAdmin(){
        require(msg.sender == admin, "you are not admin");
        _;
    }

    //Set the address of the bank administrator
    modifier onlyBank () {
        require(msg.sender == _bank_Address, "The address is not bank");
        _;

    }


    //Record the lockup time changed by the administrator
    event LockTimeRecord(uint indexed time , uint indexed timechange);
    //User pledge record
    event MortgageValueAmount (address indexed userAddress,  uint indexed  month, uint indexed  mortgageAmount);
    //Administrator withdrawal records
    event AdminTakeValue(address indexed Mining, address indexed Admin, uint indexed value);
    //Alternate administrator
    event AdminChange(address indexed Admin, address indexed newAdmin);
    //recorded information
    mapping(address => Record[]) public lockUpTotal;

    //Replacing an Administrator
    function setAdmin(address newAdmin) public onlyAdmin {
        require(msg.sender == admin, "you are not admin");
        emit AdminChange(admin, newAdmin);
        admin = newAdmin;
    }
    //Set the lockup time
    function setLockTime(uint time) public onlyAdmin {
        require(msg.sender == admin, "you are not admin");
        emit LockTimeRecord(_lockTime, time);
        _lockTime = time;

    }
    //Gets the number of pens locked by the user
    function lockUpTotalLength(address userAddress) public view returns (uint length){
        return length = lockUpTotal[userAddress].length;
    }

    //The administrator takes money
    function getValue(address[] memory tokenArr) public onlyAdmin {
        require(msg.sender == admin, "You are not admin");
        for (uint i = 0; i < tokenArr.length; i++) {
            uint Amount = IERC20(tokenArr[i]).balanceOf(address(this));
            TransferHelper.safeTransfer(tokenArr[i], msg.sender, Amount);
            emit AdminTakeValue(address(this), msg.sender, Amount);
        }
    }

    //Get user lock-up
    function getUserLockNum() public view returns (uint){
        uint lockNum = 0;
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        for (uint i = 0; i < lockUpTotal[msg.sender].length; i++) {
            Record memory res = lockUpTotal[msg.sender][i];
            if (blockTime >= res.startTime && blockTime < res.endTime) {
                uint amount = (res.amount.mul(4).div(5)).mul((blockTime - res.startTime)).div(_lockTime);
                lockNum = (res.amount.mul(4).div(5)).sub(amount).add(lockNum);
            }
        }
        return lockNum;
    }
    //Get user extractable
    function getUserExtractable() public view returns (uint){
        uint extractable = 0;
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        for (uint i = 0; i < lockUpTotal[msg.sender].length; i++) {
            Record memory res = lockUpTotal[msg.sender][i];
            if (blockTime >= res.startTime && blockTime < res.endTime) {
                uint amount = (res.amount.mul(4).div(5)).mul((blockTime - res.startTime)).div(_lockTime);
                extractable = amount.sub(res.extracted).sub(res.mortgage).add(extractable);
            }
            if (blockTime >= res.endTime) {
                extractable = res.amount.mul(4).div(5).sub(res.extracted).sub(res.mortgage).add(extractable);
            }
        }
        return extractable;
    }
    //Extract All
    function extract() public {
        uint extractable = 0;
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        for (uint i = 0; i < lockUpTotal[msg.sender].length; i++) {
            Record memory res = lockUpTotal[msg.sender][i];
            if (blockTime >= res.startTime && blockTime < res.endTime) {
                uint amount = (res.amount.mul(4).div(5)).mul((blockTime - res.startTime)).div(_lockTime);
                uint extracted = amount.sub(res.extracted).sub(res.mortgage);
                extractable = extracted.add(extractable);
                res.extracted += extracted;
            }
            if (blockTime >= res.endTime) {
                uint extracted = res.amount.mul(4).div(5).sub(res.extracted).sub(res.mortgage);
                extractable = extracted.add(extractable);
                res.extracted += extracted;
            }
        }
        userTotalReceived[msg.sender] += extractable;
        TransferHelper.safeTransfer(_Rbt, msg.sender, extractable);
    }
    //Extract a certain amount
    function extractOne(uint index) public returns (uint){
        uint blockTime = block.timestamp;
        Record memory res = lockUpTotal[msg.sender][index];
        uint lockNum = ((res.amount.mul(4)).div(5)).mul((res.endTime - blockTime).div(_lockTime));
        uint extractable = ((res.amount.sub(lockNum)).sub(res.extracted)).sub(res.mortgage);
        res.extracted = res.extracted.add(extractable);

        TransferHelper.safeTransfer(_Rbt, msg.sender, extractable);
        return extractable;
    }
    //Obtain the total amount of ore, unreleased, extractable
    function getRbtRecord() public view returns (uint, uint, uint){
        uint allRbt = 0;
        uint lockNum = 0;
        uint extractable = 0;
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        for (uint i = 0; i < lockUpTotal[msg.sender].length; i++) {
            Record memory res = lockUpTotal[msg.sender][i];
            allRbt = allRbt.add(res.amount);

            if (blockTime >= res.startTime && blockTime < res.endTime) {

                uint amount = (res.amount.mul(4).div(5)).mul((blockTime - res.startTime)).div(_lockTime);

                extractable = amount.sub(res.extracted).sub(res.mortgage).add(extractable);

                lockNum = (res.amount.mul(4).div(5)).sub(amount).add(lockNum);
            }

            if (blockTime >= res.endTime) {

                extractable = res.amount.mul(4).div(5).sub(res.extracted).sub(res.mortgage).add(extractable);
            }

        }

        return (allRbt, lockNum, extractable);
    }
    //pledge
    function mortgage(address userAddress, uint deadline, uint mAmount) public {
        require(deadline==0||deadline==3||deadline==6||deadline==12||deadline==24||deadline==36,"Deposit month error");
        // require(msg.sender == _bank_Address, 'The deadline is not a bank');
        // uint blockTime = uint32(block.timestamp % 2 ** 32);
        //质押到期时间
        // uint endOfPle = blockTime.add(deadline);
        //质押时间大于开始释放时间
        // require(endOfPle > lockUpTotal[userAddress][witch].startTime, 'No extraction time');
        // require(lockUpTotal[userAddress][witch].amount > mAmount, ' Insufficient Balance');
        // lockUpTotal[userAddress][witch].mortgage = lockUpTotal[userAddress][witch].mortgage.add(mAmount);
        // TransferHelper.safeTransfer(_Rbt, _bank_Address, mAmount);
        // uint month = deadline.mod(2592000);
        IRbBank(_bank_Address).depositToken(msg.sender , deadline ,mAmount);

        emit MortgageValueAmount(msg.sender, deadline, mAmount);
    }

}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";

abstract contract MiningBase {
    using SafeMath for uint;//安全库
    //用户总领取

    address public _Rbt;//RBT地址
    address public _bank_Address;//银行地址
    address public admin;//管理员地址
    uint public _lockTime = 365 days;//锁仓时间
    mapping(address => uint) public userTotalReceived;//获得合约的总提取

    struct Record {
        uint startTime;//锁仓开始时间
        uint endTime;//全部释放时间
        uint amount;//兑换 RBTtoken数量
        uint extracted;//已提取
        uint price;//设置交易价格
        uint mortgage;//质押数量
    }

    //设置管理员地址
    modifier onlyAdmin(){
        require(msg.sender == admin, "you are not admin");
        _;
    }

    //设置银行管理员的地址
    modifier onlyBank () {
        require(msg.sender == _bank_Address, "The address is not bank");
        _;

    }

    //记录管理员更改的锁仓时间
    event LockTimeRecord(uint indexed time, uint indexed timechange);
    //用户质押记录
    event MortgageValueAmount (address indexed userAddress, uint indexed month, uint indexed mortgageAmount);
    //管理员取钱记录
    event AdminTakeValue(address indexed Mining, address indexed Admin, uint indexed value);
    //记管理员交替
    event AdminChange(address indexed Admin, address indexed newAdmin);
    //记录信息
    mapping(address => Record[]) public lockUpTotal;

    //更换管理员
    function setAdmin(address newAdmin) public onlyAdmin {
        require(msg.sender == admin, "you are not admin");
        emit AdminChange(admin, newAdmin);
        admin = newAdmin;
    }
    //设置锁仓时间
    function setLockTime(uint time) public onlyAdmin {
        require(msg.sender == admin, "you are not admin");
        emit LockTimeRecord(_lockTime, time);
        _lockTime = time;

    }
    //获取用户锁仓多少笔
    function lockUpTotalLength(address userAddress) public view returns (uint length){
        return length = lockUpTotal[userAddress].length;
    }

    //管理员取钱
    function getValue(address[] memory tokenArr) public onlyAdmin {
        require(msg.sender == admin, "You are not admin");
        for (uint i = 0; i < tokenArr.length; i++) {
            uint Amount = IERC20(tokenArr[i]).balanceOf(address(this));
            TransferHelper.safeTransfer(tokenArr[i], msg.sender, Amount);
            emit AdminTakeValue(address(this), msg.sender, Amount);
        }
    }

    /*
    *获取用户锁仓
    */
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
    /*
    *获得用户可提取的
    */
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

    /*
    *提取提取某一笔
    */
    function extractOne(uint index) public returns (uint){
        uint blockTime = block.timestamp;
        Record memory res = lockUpTotal[msg.sender][index];
        uint lockNum = ((res.amount.mul(4)).div(5)).mul((res.endTime - blockTime).div(_lockTime));
        uint extractable = ((res.amount.sub(lockNum)).sub(res.extracted)).sub(res.mortgage);
        res.extracted = res.extracted.add(extractable);

        TransferHelper.safeTransfer(_Rbt, msg.sender, extractable);
        return extractable;
    }
    //获取 挖矿总量、未释放、可提取
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
}

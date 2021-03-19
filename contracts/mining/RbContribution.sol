pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/mining/IRbConsensus.sol";
import "../lib/TransferHelper.sol";
import "./MiningBase.sol";
//贡献挖矿

contract RbContribution is MiningBase {
    using SafeMath for uint;//安全库

    //已经挖出：用于展示
    uint public digOutAmount;
    //全部领取：用于展示
    uint public allReceived;
    //RBD地址
    address public _RBD;
    //共识合约地址
    address public rbConsensus;
    //银行地址
    address public bankAddress;
    //补充信息
    uint public transferPrice = 1;
    //兑换记录每一笔信息
    event PurchaseRecord (address  User , uint indexed tokenAmount , uint indexed rbtAmount ,address indexed tokenAddress);

    //协调器参数
    constructor(
        address rbd,
        address rbt,
        address bank,
        address Adamin
    ) public {
        _RBD = rbd;
        _Rbt = rbt;
        admin = Adamin;
        bankAddress = bank;
    }

    //设置共识合约地址：兑换价格需要在共识合约里取
    function setrbConsensus(address addr) public onlyAdmin {
        rbConsensus = addr;
    }

    /*
    *   RBD --> RBT 兑换
    */


    function getRBT(uint amount) public {
        uint RbtransferPrice = IRbConsensus(rbConsensus).getRbtPrice();
        uint amountRbt = amount.mul(100).div(RbtransferPrice);
        TransferHelper.safeTransferFrom(_RBD, msg.sender, address(this), amount);
        TransferHelper.safeTransfer(_Rbt, msg.sender, amountRbt.div(5));
        Record memory rec = Record({
        startTime : block.timestamp,
        endTime : block.timestamp + _lockTime,
        amount : amountRbt,
        extracted : 0,
        price : transferPrice,

        mortgage : 0

        });
        lockUpTotal[msg.sender].push(rec);

        userTotalReceived[msg.sender] = userTotalReceived[msg.sender].add(amountRbt);
        allReceived = allReceived.add(amountRbt);
        digOutAmount = digOutAmount.add(amountRbt);
        emit PurchaseRecord (msg.sender , amount , amountRbt ,_RBD);

    }


}

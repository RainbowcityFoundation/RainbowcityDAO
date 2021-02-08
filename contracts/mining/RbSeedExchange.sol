pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "./MiningBase.sol";

//种子轮兑换
contract RbSeedExchange is MiningBase {
    using SafeMath for uint;//安全库
    //累计挖出总量 ,这里是RBT展示查询数据
    uint public digOutAmount;
    //累计已领 ，这里是RBT展示查询数据
    uint public allReceived;
    //兑换记录每一笔信息
    event PurchaseRecord (address  User , uint indexed tokenAmount , uint indexed rbtAmount ,address indexed tokenAddress);

    //SEED地址
    address private _RBT_SEED;
    uint public exchangeRate;
    //协调器传参
    constructor (
        address seed,
        address rbt,
        address Aadmin
    ){
        _RBT_SEED = seed;
        _Rbt = rbt;
        admin = Aadmin;
    }
    //银行地址
    address private BANK_ADDRESS;
    /*设置兑换率 */
    function setExchangeRate(uint rate) public onlyAdmin {
        exchangeRate = rate;
    }
    /*
    *   RBTSEED --> RBT 兑换
    */
    function exchange(uint value) public {

        TransferHelper.safeTransferFrom(_RBT_SEED, msg.sender, address(this), value);
        TransferHelper.safeTransfer(_Rbt, msg.sender, value.div(5));
        uint blockTime = block.timestamp;
        Record memory recordrec = Record({
        startTime : blockTime,
        endTime : blockTime + _lockTime,
        amount : value - exchangeRate,
        price : exchangeRate,

        extracted : 0,
        mortgage : 0

        });
        lockUpTotal[msg.sender].push(recordrec);
        allReceived = allReceived.add(value);
        digOutAmount = digOutAmount.add(value);
        emit PurchaseRecord (msg.sender , value , value , _RBT_SEED);
    }

}

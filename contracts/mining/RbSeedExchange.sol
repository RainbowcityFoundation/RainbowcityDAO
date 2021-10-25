pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "./MiningBase.sol";

//Seed round exchange
contract RbSeedExchange is MiningBase {
    using SafeMath for uint;//Security library
    //Cumulative total amount of mining, here is RBT display query data
    uint public digOutAmount;
    //Accumulated received, here is the RBT display query data
    uint public allReceived;
    //Exchange records for every piece of information
    event PurchaseRecord (address  User , uint indexed tokenAmount , uint indexed rbtAmount ,address indexed tokenAddress);

    //SEED address
    address private _RBT_SEED;
    uint public exchangeRate;
    //Coordinator parameter transfer
    constructor (
        address seed,
        address rbt,
        address Aadmin
    ){
        _RBT_SEED = seed;
        _Rbt = rbt;
        admin = Aadmin;
    }
    //Bank address
    address private BANK_ADDRESS;
    //Set exchange rate
    function setExchangeRate(uint rate) public onlyAdmin {
        exchangeRate = rate;
    }
    //RBTSEED --> RBT exchange
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

pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/mining/IRbConsensus.sol";
import "../lib/TransferHelper.sol";
import "./MiningBase.sol";
//Contribute to mining

contract RbContribution is MiningBase {
    using SafeMath for uint;//Security library

    //Already dug out: for display
    uint public digOutAmount;
    //Collect all: for display
    uint public allReceived;
    //RBD address
    address public _RBD;
    //Consensus contract address
    address public rbConsensus;
    //Bank address
    address public bankAddress;
    //Additional information
    uint public transferPrice = 1;
    //Exchange records for every piece of information
    event PurchaseRecord (address  User , uint indexed tokenAmount , uint indexed rbtAmount ,address indexed tokenAddress);

    //Coordinator parameters
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

    //Set the consensus contract address: the exchange price needs to be taken in the consensus contract
    function setrbConsensus(address addr) public onlyAdmin {
        rbConsensus = addr;
    }

    //RBD --> RBT exchange
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

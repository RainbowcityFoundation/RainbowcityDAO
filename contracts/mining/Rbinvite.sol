pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/mining/IRbConsensus.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "./MiningBase.sol";

//邀请挖矿
contract Rbinvite is MiningBase {
    using SafeMath for uint;//安全库
    //个人累计兑换
    mapping(address => uint) public cumuRbt;
    //以挖出的总量用于展示
    uint public digOutAmount;
    //RBTEX地址
    address public _RBTEX;
    //共识地址
    address public RbConsensus;
    //全部领取：用于展示
    uint public allReceived;
 
    //协调器传参
    constructor(
        address ex,
        address rbt,
        address rbConsensus,
        address Aadmin
    ) public {
        _RBTEX = ex;
        _Rbt = rbt;
        RbConsensus = rbConsensus;
        admin = Aadmin;
    }
    /*
    *   RBTEX --> RBT 兑换
    */
    function getRBT(uint amount) public {
        (uint total,uint examount) = IRbConsensus(RbConsensus).exchangeRatio(msg.sender);
        TransferHelper.safeTransferFrom(_RBTEX, msg.sender, address(this), total);
        TransferHelper.safeTransfer(_Rbt, msg.sender, examount.div(5));
        //数据展示
        allReceived = allReceived.add(examount.div(5));
        digOutAmount = digOutAmount.add(examount);
        cumuRbt[msg.sender] += examount;
    }

}

pragma solidity =0.8.0;


import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../interface/mining/IOpenOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRbtVip.sol";
import "./MiningBase.sol";


//共识挖矿
contract RbConsensus is MiningBase {

    using SafeMath for uint;//安全库
    uint public transferOnePrice;
    uint public transferPrice;//交易价格
    uint public cumulRbt;//每轮总量
    address public source;//预言机来源
    address public vipAddress;//vip地址


}

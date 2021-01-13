pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/TransferHelper.sol";
import "../interface/mining/IOpenOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MiningBase.sol";

//种子轮认购
contract RbSeedSubscription is MiningBase {
    //安全库
    using SafeMath for uint;
    //RBT地址
    address public _RBT_SEED;
    //预言机地址来源
    address public source;
    //剩余认购数量
    uint public isSubSeedsLeftNum;
    uint public totalAmount = 30000000 *10 **18;
    //已经挖出
    uint public digOutAmount;
    //映射可认购代币
    mapping(address => bool) public tokenAllow;
    //记录认购
    mapping(address => recordRbSeedSubscription[]) public  RbSeedSubscriptionRecord;
    //购买记录每一笔信息
    event PurchaseRecord(address user , uint indexed tokenAmount, uint indexed rbtSeedAmount, address indexed tokenAddress);
    //认购参数
    struct recordRbSeedSubscription {
        uint curRate;//rbtseed单价
        uint time;//兑换时间方便查询
        uint amount;//兑换数量
    }
    //协调器传参
    constructor(
        address seed,
        address Aadmin
    ) public {
        admin = Aadmin;
        _RBT_SEED = seed;
        isSubSeedsLeftNum = 1000000 * 10 ** 18;
        source = 0xfCEAdAFab14d46e20144F48824d0C09B1a03F2BC;

    }
    //本轮认购剩余金额（达到1_000_000 提高价格）
    uint public curRate = 100;
    //每轮数量
    uint public account = 1000000 * 10 ** 18;

    //预言机获取价格
    function getPrice(string memory K) public view returns (uint64 a, uint64 b){

        (a, b) = IOpenOracle(0x00c4770D3Feb38ad07f879Abd96619FBdeb00520).get(source, K);
    }

    bool public turnOnOff;
    //添加代币的开关 
    function setTurnOnOff(bool turnType) public onlyAdmin {
        turnOnOff = turnType;
    }
    //管理员设置认购代币
    function setTokenAllow(address[] memory allowToken) public onlyAdmin {
        require(turnOnOff == false, "0");
        for (uint i = 0; i < allowToken.length; i++) {
            if (!tokenAllow[allowToken[i]]) {
                tokenAllow[allowToken[i]] = true;
            }
        }
    }

    //认购RBTSEED
    function seedSubscription(uint value, string memory tokenName, address token) public {

        require(tokenAllow[token] == true, "the token not allow");
        require(value > 0, "input price error");
        require(isSubSeedsLeftNum - value >= 0, "RBTSEED is not enough");
        require(token != address(0), "token is not 0 address");
        //(,uint64 price) = getPrice(tokenName);
        //uint rbtSeedAmount = value.mul(price * 10 ** 6).mul(1000).div(curRate);
        uint rbtSeedAmount = value.mul(1000).div(curRate);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
        TransferHelper.safeTransfer(_RBT_SEED, msg.sender, rbtSeedAmount);
        account = account.sub((value.mul(1000)).div(curRate));
        isSubSeedsLeftNum = isSubSeedsLeftNum.sub(value);
        recordRbSeedSubscription memory recordrec = recordRbSeedSubscription({

        curRate : curRate,
        time : block.timestamp,
        amount : value
        });
        RbSeedSubscriptionRecord[msg.sender].push(recordrec);
        if (isSubSeedsLeftNum == 0) {
            curRate = curRate.add(10);
            isSubSeedsLeftNum = 1000000 * 10 ** 18;
            totalAmount-=isSubSeedsLeftNum;
        }
        
        emit PurchaseRecord(msg.sender, value, rbtSeedAmount, token);
    }
    //获得记录长度
    function getRecordsLength() public view returns (uint){
        return RbSeedSubscriptionRecord[msg.sender].length;
    }



}
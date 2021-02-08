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

    mapping(address => bool) public tokenAllow;//映射可认购代币

    //个人记录
    mapping(address => myRecord[]) public myRecords;
    //各个层级
    mapping(address => mapping(uint => uint)) public levelMining;
    //累计挖出总量 ,这里是RBT展示查询数据
    uint public digOutAmount;
    //累计已领 ，这里是RBT展示查询数据
    uint public allReceived;
    //购买记录每一笔信息
    event PurchaseRecord(address  user ,  uint indexed tokenAmount, uint indexed rbtAmount, address indexed tokenAddress);
    struct myRecord {
        uint received;   //我的已领
        uint myDigOutAmount;//我的累计挖出
    }

    //协调器需传递的参数
    constructor(

        address rbt,
        address bank,
        address vip,
        address Aadmin

    ) public {
        _Rbt = rbt;
        _bank_Address = bank;
        vipAddress = vip;
        transferPrice = 40;
        admin = Aadmin;
        cumulRbt = 500000 * 10 ** 18;
        source = 0xfCEAdAFab14d46e20144F48824d0C09B1a03F2BC;

    }


    //交易价格设定
    function setPrice(uint price) public onlyAdmin {
        transferPrice = price;
    }

    function getRbtPrice() public view returns(uint){
        return transferPrice;
    }

    //获取用户总领取
    function getUserTotalReceived(address addr) public view returns (uint){
        return userTotalReceived[addr];
    }
    //获取用户的获取的数量
    function getUserAmount(address sender) public view returns (uint) {
        return userTotalReceived[sender];
    }
    //获取用户层级
    function getLevelAmount(address sender, uint level) public view returns (uint){
        return levelMining[sender][level];
    }

    //预言机获取获取价格
    function getPrice(string memory K) public view returns (uint64 a, uint64 b){

        (a, b) = IOpenOracle(0x00c4770D3Feb38ad07f879Abd96619FBdeb00520).get(source, K);
    }
    //递归查询挖矿等级
    function _recursionAddAmount(address sender, uint amount, uint i) internal {
        while (i <= 7) {
            address referUser;
            if (referUser != address(0)) {
                levelMining[referUser][i] = levelMining[referUser][i].add(amount);
            } else {
                break;
            }
            i++;
            _recursionAddAmount(referUser, amount, i);
        }
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


    /**
     * -> Rbt  花费，购买rbt数量，代币地址，滑点
    */

    function getRBT(uint amount, address token, uint slip, string memory tokenName) public {
        //  (, uint64 price) = getPrice(tokenName);
        // uint amountRbt = amount.mul(price).div(10 ** 12).div(transferPrice).mul(100);
        // uint totalPrice = amount.mul(price).div(10 ** 12);
        uint amountRbt = amount.div(transferPrice).mul(100);
        uint totalPrice = amount;
        uint totalAmountRbt;
        uint oneWRbtprice = 10000*10**18*transferOnePrice/100;
        uint turnPrice =  transferPrice++;
        uint transferOnePrice = transferPrice;
        require(tokenAllow[token] == true, "the token not allow");
        require(token != address(0), "Invalid address");
        require(slip == 0 || transferPrice <= slip, "More than slippage");
        require(amountRbt >= 100 * 10 ** 18, "It's big than 100");


        // if(amountRbt > 10000*10**18 && cumulRbt > amountRbt){
        //     for(uint i = totalPrice; i > oneWRbtprice ; i-oneWRbtprice ){
        //         cumulRbt.sub(10000*10**18);
        //         transferOnePrice++;
        //         totalAmountRbt+=10000*10**18;
        //     }
        //     ++transferOnePrice;
        //     totalAmountRbt += totalPrice.mul(1).div(transferOnePrice).mul(100);
        //     amountRbt = totalAmountRbt;
        // }





        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
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
        allReceived = allReceived.add(amountRbt.div(5));
        digOutAmount = digOutAmount.add(amountRbt);

        myRecord memory myrec = myRecord({
        received : amountRbt.div(5),
        myDigOutAmount : amountRbt

        });





        //每轮可发生的购买情况
        cumulRbt = cumulRbt.sub(amountRbt);

        if (cumulRbt > amountRbt) {

            cumulRbt = cumulRbt.sub(amountRbt);
        }


        if (cumulRbt < amountRbt) {
            cumulRbt = 500000 * 10 ** 18 - (amountRbt).add(cumulRbt);
            transferPrice++;

        }

        if (cumulRbt == amountRbt) {
            cumulRbt = 500000 * 10 ** 18;
            transferPrice++;

        }


        userTotalReceived[msg.sender] = userTotalReceived[msg.sender].add(amountRbt);

        myRecords[msg.sender].push(myrec);


        emit PurchaseRecord(msg.sender, amount, amountRbt, token);
    }


    //邀请挖矿获取释放层级释放率
    function exchangeRatio(address addr) public view returns (uint, uint){
        uint amount = getUserTotalReceived(addr);
        uint ratio = 0;
        uint length = 0;
        //vip等级
        uint level = IRbtVip(vipAddress).getVipLevel(addr);


        if (level == 0) {
            length = 3;
            ratio = 5;
        }
        if (level == 1) {
            length = 5;
            ratio = 10;
        }
        if (level == 2) {
            length = 6;
            ratio = 10;
        }
        if (level == 3) {
            length = 7;
            ratio = 15;
        }

        if (level == 4) {
            length = 8;
            ratio = 15;
        }
        for (uint i = 1; i < length; i++) {
            amount += levelMining[addr][i];
        }

        return (amount, amount.mul(ratio).div(1000));
    }

}

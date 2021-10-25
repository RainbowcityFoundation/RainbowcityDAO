pragma solidity =0.8.0;


import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "../interface/mining/IOpenOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRbtVip.sol";
import "./MiningBase.sol";


//Consensus mining
contract RbConsensus is MiningBase {

    using SafeMath for uint;//Security library
    uint public transferOnePrice;
    uint public transferPrice;//Trading price
    uint public cumulRbt;//Total amount per round
    address public source;//Source of oracle
    address public vipAddress;//vip address

    mapping(address => bool) public tokenAllow;//Mapping subscribeable tokens

    //Personal records
    mapping(address => myRecord[]) public myRecords;
    //All levels
    mapping(address => mapping(uint => uint)) public levelMining;
    //Cumulative total amount of mining, here is RBT display query data
    uint public digOutAmount;
    //Accumulated received, here is the RBT display query data
    uint public allReceived;
    //Purchase record every piece of information
    event PurchaseRecord(address user, uint indexed tokenAmount, uint indexed rbtAmount, address indexed tokenAddress);

    struct myRecord {
        uint received;   //My received
        uint myDigOutAmount;//My cumulative dug out
    }

    //Parameters to be passed by the coordinator
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
        source = 0x567d5dc3b7b55d56ab246e10870cc5bdd7208da7;

    }


    //Transaction price setting
    function setPrice(uint price) public onlyAdmin {
        transferPrice = price;
    }

    function getRbtPrice() public view returns (uint){
        return transferPrice;
    }

    //Get user total receipt
    function getUserTotalReceived(address addr) public view returns (uint){
        return userTotalReceived[addr];
    }
    //Acquired the number of user acquisitions
    function getUserAmount(address sender) public view returns (uint) {
        return userTotalReceived[sender];
    }
    //Get user level
    function getLevelAmount(address sender, uint level) public view returns (uint){
        return levelMining[sender][level];
    }

    //The oracle gets the price
    function getPrice(string memory K) public view returns (uint64 a, uint64 b){

        (a, b) = IOpenOracle("0xdfd717f4e942931c98053d54qwf803a1b52838db").get(source, K);
    }
    //Recursive query mining level
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
    //Switch to add tokens
    function setTurnOnOff(bool turnType) public onlyAdmin {
        turnOnOff = turnType;
    }
    //The administrator sets up subscription tokens
    function setTokenAllow(address[] memory allowToken) public onlyAdmin {
        require(turnOnOff == false, "0");
        for (uint i = 0; i < allowToken.length; i++) {
            if (!tokenAllow[allowToken[i]]) {
                tokenAllow[allowToken[i]] = true;
            }
        }
    }


    //Rbt cost, amount of rbt purchased, token address, slippage
    function getRBT(uint amount, address token, uint slip, string memory tokenName) public {
        //  (, uint64 price) = getPrice(tokenName);
        // uint amountRbt = amount.mul(price).div(10 ** 12).div(transferPrice).mul(100);
        // uint totalPrice = amount.mul(price).div(10 ** 12);
        uint amountRbt = amount.div(transferPrice).mul(100);
        uint totalPrice = amount;
        uint totalAmountRbt;
        uint oneWRbtprice = 10000 * 10 ** 18 * transferOnePrice / 100;
        uint turnPrice = transferPrice++;
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


        //Purchases that can occur in each round
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


    //Invite mining to get the release level release rate
    function exchangeRatio(address addr) public view returns (uint, uint){
        uint amount = getUserTotalReceived(addr);
        uint ratio = 0;
        uint length = 0;
        //vip level
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

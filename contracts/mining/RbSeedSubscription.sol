pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/TransferHelper.sol";
import "../interface/mining/IOpenOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MiningBase.sol";

//Seed round subscription
contract RbSeedSubscription is MiningBase {
    //Security library
    using SafeMath for uint;
    //RBT address
    address public _RBT_SEED;
    //Source of oracle address
    address public source;
    //Remaining subscription quantity
    uint public isSubSeedsLeftNum;
    uint public totalAmount = 30000000 *10 **18;
    //Already dug out
    uint public digOutAmount;
    //Mapping subscribeable tokens
    mapping(address => bool) public tokenAllow;
    //Record subscription
    mapping(address => recordRbSeedSubscription[]) public  RbSeedSubscriptionRecord;
    //Purchase record every piece of information
    event PurchaseRecord(address user , uint indexed tokenAmount, uint indexed rbtSeedAmount, address indexed tokenAddress);
    //Subscription parameters
    struct recordRbSeedSubscription {
        uint curRate;//rbtseed unit price
        uint time;//Convenient to check the exchange time
        uint amount;//Number of exchanges
    }
    //Coordinator parameter transfer
    constructor(
        address seed,
        address Aadmin
    ) public {
        admin = Aadmin;
        _RBT_SEED = seed;
        isSubSeedsLeftNum = 1000000 * 10 ** 18;
        source = 0xfCEAdAFab14d46e20144F48824d0C09B1a03F2BC;

    }
    //The remaining amount of this round of subscription (to 1_000_000 to increase the price)
    uint public curRate = 100;
    //Number per round
    uint public account = 1000000 * 10 ** 18;

    //The oracle gets the price
    function getPrice(string memory K) public view returns (uint64 a, uint64 b){

        (a, b) = IOpenOracle(0x00c4770D3Feb38ad07f879Abd96619FBdeb00520).get(source, K);
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

    //Subscribe to RBTSEED
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
    //Get record length
    function getRecordsLength() public view returns (uint){
        return RbSeedSubscriptionRecord[msg.sender].length;
    }



}

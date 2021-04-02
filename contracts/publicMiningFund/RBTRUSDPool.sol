pragma solidity ^0.8.0;
import "../ref/PoolsRef.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract RBTRUSDPool is PoolsRef {
       using SafeMath for uint256;
    uint public numberOfFailures;  //失败次数
    constructor(address core,  address _RainbowRouter,address _token0,address _token1,address _pair ) PoolsRef(core,_RainbowRouter,_token0,_token1,_pair)  public {}


        //dcv恢复到指定价格
    function reweight() public {
          uint oraclePrice =  _getOraclePrice();
        uint consensusPrice = _getConsensusPrice();
        require (oraclePrice < consensusPrice.mul(20).div(100),'can not do now');
        //1.撤出流动性
        _removeLiquidity(token0,token1,pair.balanceOf(address(this)),0,0,address(this),type(uint).max);
        //2.用DCV中的RUSD购买RBT，使价格恢复到“共识挖矿”实时汇率价格的20%，
         _returnSpecifyPrice();
        //获取预言机最新的价格

        //3.重新添加流动性
        //todo 获取预言机token0相对token1的价格
        uint price = 100;
        uint token1Balance = IERC20(token1).balanceOf(address(this)); //rusd
        uint amountToken0 = price.mul(token1Balance);
        _addLiquidity(token0,token1,amountToken0,token1Balance,0,0,address(this),type(uint).max);
        //todo 更新预言机 获取最新价格

    }
    //检测是否达到了要求
    function _checkAchieveTheGoal() internal{
        uint oraclePrice =  _getOraclePrice();
        uint consensusPrice = _getConsensusPrice();
        //没达到要求
       if(oraclePrice < consensusPrice.mul(20).div(100)){
            numberOfFailures++;
           if(numberOfFailures == 3){
               //todo  调整借贷使用率
                numberOfFailures = 0;
           }
       }
    }

    //将价格拉到指定价格
    function _returnSpecifyPrice() internal{
        (uint256 otherReserves, uint256 rusdReserves) = getReserves();
        if (otherReserves == 0 || rusdReserves == 0) {
            return;
        }
        // todo 获取共识挖矿价格的20%是多少
        uint _peg = 100;
        uint256 amountRusd = _getAmountToPeg(otherReserves, rusdReserves, _peg);
        _swap(amountRusd, rusdReserves, otherReserves);
    }
    

    /*
        @dev获取公示挖矿价格
    */
    function _getConsensusPrice() internal view returns(uint) {
        return 100;
    }

    //获取预言机里RBT的价格
    function _getOraclePrice() internal view returns(uint) {
        return 100;
    }
}

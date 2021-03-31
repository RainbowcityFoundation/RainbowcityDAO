pragma solidity ^0.8.0;

import "../interface/uniswap/IUniswapV2Router02.sol";
import "../interface/uniswap/IUniswapV2Pair.sol";
import "../lib/UniswapV2Library.sol";
import "../lib/Babylonian.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CoreRef.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract PoolsRef is CoreRef {
    using SafeMath for uint256;
    using Babylonian for uint256;
    address public token0;
    IUniswapV2Pair public pair;
    address public token1;  //RUSD
    IUniswapV2Router02 public RainbowRouter;
    uint public lastDepositTime;
    constructor(address core,  address _RainbowRouter,address _token0,address _token1,address _pair )  CoreRef(core)  {
        RainbowRouter = IUniswapV2Router02(_RainbowRouter);
        token0 = _token0;
        token1 = _token1;
        pair = IUniswapV2Pair(_pair);
    }
    //todo 设置只能来自dcv
    function depositToPools() public {
        require(block.timestamp >= lastDepositTime + 14400,'time is not in');
        _saveToDebit();

        //将RUSD一半兑换为所需的TOKEN进行流动性添加。
        //todo 获取预言机token0相对token1的价格
        uint price = 100;
        uint token1Balance = IERC20(token1).balanceOf(address(this));
        //兑换一半
        uint amountToken0 = price.mul(token1Balance).mul(50).div(100);

        uint amountToken1 = token1Balance.mul(50).div(100);
        //将RUSD分别注入四个流动性池子，另外一半币种的资金用RUSD从对应的池子里购买，RBT——RUSD，RBD——RUSD，RBT-Seed——RUSD，RBT-EX——RUSD
         _addLiquidity(token0,token1,amountToken0,amountToken1,0,0,address(this),type(uint).max);
        lastDepositTime = block.timestamp;
    }
    //将ETH/BTC添加到借贷里面去，生成RUSD
    function _saveToDebit() internal {}




    function _getAmountToPeg(
        uint256 reserveTarget,
        uint256 reserveOther,
        uint peg
    ) internal pure returns (uint256) {
        uint256 radicand = peg.mul(reserveTarget).mul(reserveOther);
        uint256 root = radicand.sqrt();
        if (root > reserveTarget) {
            return (root - reserveTarget).mul(1000).div(997);
        }
        return (reserveTarget - root).mul(1000).div(997);
    }

    function getReserves() public view  returns (uint256 otherReserves, uint256 rusdReserves)
    {
        address uToken0 = pair.token0();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (otherReserves, rusdReserves) = token0 == uToken0
        ? (reserve0, reserve1)
        : (reserve1, reserve0);
        return (otherReserves, rusdReserves);
    }

    function _swap(
        uint256 amountRusd,
        uint256 rusdReserves,
        uint256 otherReserves
    ) internal {
        uint256 balance = IERC20(token1).balanceOf(address(this)).mul(50).div(100);
        uint256 amount = Math.min(amountRusd, balance);

        uint256 amountOut =
        UniswapV2Library.getAmountOut(amount, rusdReserves, otherReserves);

        (uint256 amount0Out, uint256 amount1Out) =
        pair.token0() == token0
        ? (uint256(0), amountOut)
        : (amountOut, uint256(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    //添加流动性
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) internal  {
        RainbowRouter.addLiquidity(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,to,deadline);
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline) internal {
            RainbowRouter.removeLiquidity(tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline);
    }



    // //添加流动性ETH
    // function _addLiquidityETH(uint ethAmount,uint liquidity, address token,uint deadline) internal {
    //     router.addLiquidityETH{value: ethAmount}(
    //         token,
    //         liquidity,
    //         0,
    //         0,
    //         address(this),
    //         deadline
    //     );
    // }
}

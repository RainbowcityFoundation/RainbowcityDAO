pragma solidity ^0.8.0;
import "../interface/bank/IRbBank.sol";
import "../interface/token721/IRbtDeposit721.sol";
import '../lib/TransferHelper.sol';
import "../ref/CoreRef.sol";

contract RainbowBank is CoreRef, IRbBank{
    IRbtDeposit721 deposit;
    //记录上一次银行余额 在这里缺少获取银行余额的方法
    uint private reserve;
    address rbt;
    uint amount;
    
    //构造函数
    constructor(address core)CoreRef(core){}

    //初始化
    function init(address _rbt,address _deposits) public {
        rbt = _rbt;
        deposit=IRbtDeposit721(_deposits);
    }
    
     //存款+铸币
    function depositToken(address to,uint month,uint value) external override{
        require(month==0||month==3||month==6||month==12||month==24||month==36,"Deposit month error");
        //将钱转移到银行地址
        TransferHelper.safeTransferFrom(rbt,to,address(this), value);
        //增发代币
        deposit.mint(to, value, month);
        //查看银行余额
        uint balance=IERC20(rbt).balanceOf(address(this));
        //更新银行金额
        amount=balance-reserve;
        reserve = balance;
        emit DepositToken(to,month,value);
    }

    //取款，烧毁存款令牌
    function withdrawa(address to,uint tokenId) external override{
        //定期的时间当小于有效时间时，无法提取
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        //uint value=deposit.amount(tokenId)-1000;
        uint value=amount;
        require(blockTime>=deposit.expire(tokenId),'unable to extract');
        TransferHelper.safeTransfer(rbt, to, value);
        deposit.burn(tokenId);
        //更新一下银行数据       
        uint balance=IERC20(rbt).balanceOf(address(this)); 
        reserve =balance ;       
        emit Withdrawa(to,tokenId);
    }
}
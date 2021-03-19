pragma solidity ^0.8.0;
import "../../interface/token721/IRbtDeposit721.sol";
import "../RainbowBank.sol";
import "../../ref/CoreRef.sol";
contract LoanMarket is CoreRef{
    struct LoanRecording{
        uint tokenId;//令牌id
        uint id;//令牌所在的id
        uint amount;//凭证里的钱
        uint money;//抵押想借多少钱
        uint day;//想借的天数
        uint dayRate;//日利息
        uint interest;//利息
        uint contango;//延期一天的利息
        uint status;//借款状态  0未借出，1借出
        address owner;//所有者地址 
        address lender;//购买人地址
    }
    
    LoanRecording[] public list;
    IRbtDeposit721 deposit;
    address rbt;
    //第三方中介地址第三方中介地址

    address agent;
    event MortgageMarket(uint  tokenId,uint amount ,uint day ,uint dayRate);
    event Repayment(uint indexed id,uint indexed day,uint indexed value);
    event RepealMortgage(uint indexed id);
    ///构造函数
    constructor(address core)CoreRef(core){}

    //初始化
    function init(address _agent,address _deposits,address _rbt) public {
        agent=_agent;
        deposit=IRbtDeposit721(_deposits);
        rbt=_rbt;
    }

    //抵押凭证市场
    function mortgageMarket(uint tokenId,uint amount ,uint day ,uint dayRate)public{
        require(deposit.ownerOf(tokenId)==msg.sender);
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        //uint expireTime=blockTime+(day*86400);
        //借出day天后的利润
        uint interest =amount*(dayRate*day);
        //令牌存款的钱     
        uint mortgageAmount=deposit.amount(tokenId);
        //逾期利息（制定者待定）
        uint contango=dayRate*2;
        uint id=list.length+1;
        LoanRecording memory record=LoanRecording({
             tokenId:tokenId,
             id:id,
             amount:mortgageAmount,//凭证里的钱
             money:amount,//想要借多少钱
             day:day,//借的天数
             dayRate:dayRate,
             interest:interest,
             contango:contango,//逾期利率
             status:0,
             owner:deposit.ownerOf(tokenId),//所有者地址
             lender:address(0)
         });
         list.push(record);
        //贷款人将存款令牌交给第三方中介
        deposit.safeTransferFrom(msg.sender,agent, tokenId);
        emit MortgageMarket(tokenId,amount,day,dayRate);
    }

    //撤销市场上的抵押凭证
    function repealMortgage(uint id)public{
        require(msg.sender==list[id-1].owner&&list[id-1].status==0,"The current user has no permissions");
        //第三方中介归还将令牌归还贷款人
        deposit.safeTransferFrom(agent,msg.sender, list[id-1].tokenId);
        //删除在list中的记录
        delete list[id-1];
        emit RepealMortgage(id);
    }

    //出款人，如果超出借款时间，额外添加延期费用
    function lend(uint id,uint value)public{
        require(list[id-1].money==value,'Incorrect bid');
        //出资人将rbt打给借款人
        TransferHelper.safeTransferFrom(rbt,msg.sender,list[id-1].owner,value);
        //更改凭证状态
        list[id-1].status=1;
        //将零地址更换成购买人地址
        list[id-1].lender=msg.sender;
    }

    //还款
    function repayment(uint id,uint day,uint value)public{
        //银行手续费千分之五（待定）
        uint serviceCharge=(list[id-1].money+list[id-1].money*(list[id-1].dayRate/100)*day)*5/1000;
        //利息
        if(day<=list[id-1].day){
            require(value>=list[id-1].money+list[id-1].money*(list[id-1].dayRate/100)*day+serviceCharge);
            //第三方收取手续费
            TransferHelper.safeTransferFrom(rbt,msg.sender,agent ,serviceCharge);
            //还钱 将钱转给出款人
            TransferHelper.safeTransferFrom(rbt,msg.sender,list[id-1].lender ,list[id-1].money+list[id-1].money*(list[id-1].dayRate/100)*day);
            //将令牌归还
            deposit.safeTransferFrom(agent, msg.sender, list[id-1].tokenId);
        }else if (day-list[id-1].day<=3){ //限定延期最多三天
            uint amount=list[id-1].money+list[id-1].interest+(day-list[id-1].day)*list[id-1].contango/100;
            require(value==amount+serviceCharge);
            //第三方收取手续费
            TransferHelper.safeTransferFrom(rbt,msg.sender,agent,serviceCharge);
            //还钱 将钱转给出款人
            TransferHelper.safeTransferFrom(rbt,msg.sender, list[id-1].lender, amount);
            //将令牌归还
            deposit.safeTransferFrom(agent, msg.sender, list[id-1].tokenId);
        }else if (day-list[id-1].day>3){
            //被清算了
            //将令牌给出款人
            deposit.safeTransferFrom(agent, list[id-1].lender, list[id-1].tokenId);
        }
        emit  Repayment(id,day,value);
    }
}
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


import "../token721/Governance721.sol";
import "../lib/TransferHelper.sol";

contract BIncome {
    
    
    address public admin;
    Governance721 public rbtElf;
    Governance721 public rbtEnvoy;
    Governance721 public rbtPartner;
    Governance721 public rbtNode;
    mapping (address => uint256) public amount;
    address[] public users;
    constructor(address manager,address rbtElfAddress,address rbtEnvoyAddress,address rbtPartnerAddress,address rbtNodeAddress)  public {
        admin = manager;
         rbtElf = Governance721(rbtElfAddress);
        
        rbtEnvoy =Governance721(rbtEnvoyAddress);
        
        rbtPartner=Governance721(rbtPartnerAddress);
       
        rbtNode =Governance721(rbtNodeAddress);
      
    }
    
    
     
     //分配总数
     uint256 public totalSupply;
     uint256 public Supply;
     function getEcology() public {
         uint256 i=0;
        while(i < users.length){
            address user = users[i];
            //个用户社区精灵令牌
             uint256  elfSum =rbtElf.totalSupply();
             uint256 myElfNum=rbtElf.usableBalanceOf(user);
             uint256 elfSupply=totalSupply*25/100*myElfNum/elfSum;
            //  TransferHelper.safeTransfer(token,ownerAddress,elfSupply);
             //用户大使令牌
             uint256 envoySum=rbtEnvoy.totalSupply();
             uint256 myEnvoyNum=rbtEnvoy.usableBalanceOf(user);
             uint256 envoySupply=totalSupply*25/100*myEnvoyNum/envoySum;
            //   TransferHelper.safeTransfer(token,ownerAddress,envoySupply);
              //用户合伙人令牌
             uint256 parterSum=rbtPartner.totalSupply();
             uint256 myParterNum=rbtPartner.usableBalanceOf(user);
             uint256 parterSupply=totalSupply*25/100*myParterNum/parterSum;
            //   TransferHelper.safeTransfer(token,ownerAddress,parterSupply);
              //用户超级节点
             uint256 nodeSum=rbtNode.totalSupply();
             uint256 myNodeNum=rbtNode.usableBalanceOf(user);
             uint256 nodeSupply=totalSupply*25/100*myNodeNum/nodeSum;
            //   TransferHelper.safeTransfer(token,ownerAddress,nodeSupply);
            Supply = elfSupply+envoySupply+parterSupply+nodeSupply;
            amount[user] += Supply;
            Supply = 0;
          }
         
     }
     function getToken(address token) public{
         uint tokenAmount = amount[msg.sender];
         TransferHelper.safeTransfer(token,msg.sender,tokenAmount);
         
     }
    
}
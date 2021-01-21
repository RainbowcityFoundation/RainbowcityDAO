pragma solidity ^0.8.0 ;
interface IRbBank  {

     event DepositToken(address indexed to,uint indexed month,uint indexed value);

     event Withdrawa(address indexed to,uint indexed tokenId);

     function depositToken(address to,uint month,uint value)  external ;

     function withdrawa(address to,uint tokenId) external ;

}
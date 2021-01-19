pragma solidity ^0.8.0;

interface IFundManagement {
  
    function parliamentsVoteProposal(uint id,uint stage) external;

    function receiveToken(uint id,uint stage) external returns(string[] memory where,uint[] memory portion );
}

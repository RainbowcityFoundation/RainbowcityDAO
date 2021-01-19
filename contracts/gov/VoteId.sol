pragma solidity ^0.8.0;
import '../interface/gov/IVoteId.sol';
contract VoteId is IVoteId{
    uint public voteId;
    function incrVoteId() external  override returns(uint) {
       return voteId++;
    }
}

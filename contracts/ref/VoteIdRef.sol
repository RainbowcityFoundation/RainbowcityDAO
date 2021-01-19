pragma solidity ^0.8.0;
import '../interface/gov/IVoteId.sol';
abstract contract VoteIdRef {
    IVoteId public voteIdAddress;
    constructor(address voteIdAddr)  {
        voteIdAddress = IVoteId(voteIdAddr);
    }
}
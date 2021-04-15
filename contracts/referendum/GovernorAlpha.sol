pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// Forked from Compound
// See https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
contract GovernorAlpha {
    /// @notice The name of this contract
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "RainBow Governor Alpha";

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public pure returns (uint) { return 25000000e18; } // 25,000,000 = 2.5% of Tribe

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) { return 2500000e18; } // 2,500,000 = .25% of Tribe

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 3333; } // ~0.5 days in blocks (assuming 13s blocks)
    function votingCommunityDelay() public pure returns (uint) { return 93324; } // ~14 days in blocks (assuming 13s blocks)

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 46662; } // ~7 days in blocks (assuming 13s blocks)
    function votingFastPeriod() public pure returns (uint) { return 6666; } // ~1 days in blocks (assuming 13s blocks)

    /// @notice The address of the Fei Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Fei governance token
    TribeInterface public tribe;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    uint[] public voteProposal; //当前正在公投的普通提案为数组的0号位，无论是社区发起的还是基金会发起的，唯一! 其余的等待

    struct Proposal {
        uint id;

        address proposer;

        uint eta;

        address[] targets;

        uint[] values;

        string[] signatures;

        bytes[] calldatas;

        uint startBlock;

        uint endBlock;

        uint forVotes;

        uint againstVotes;

        bool canceled;

        bool executed;

        Launch launchType;

        Emergency emergencyType;

        uint prepareVotes; //准备期的票数，只有RIP-COMMUNITY可用

        uint publicityPeriodVotes; //公示期票数，代表反对的票数，所有类型的提案都得用，达到50%则提案失败。

        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted;

        bool support;

        uint votes;
    }
    
    

    enum Launch {Foundation,Community}
    enum Emergency{Normal,Fast}
    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(address timelock_, address tribe_, address guardian_) public {
        timelock = TimelockInterface(timelock_);
        tribe = TribeInterface(tribe_);
        guardian = guardian_;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description,Emergency emergency) public returns (uint) {
        //todo 校验此人有没有RBT-vote
        // require(tribe.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorAlpha: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha: one live proposal per proposer, found an already pending proposal");
        }

        //todo 获取基金会地址
        address foundation;
        
        Launch launch =  (msg.sender == foundation) ? Launch.Foundation : Launch.Community;
       

        if(emergency == Emergency.Fast) require(msg.sender == foundation,'no access to Fast');

        uint startBlock = (launch == Launch.Community) ?  add256(block.number, votingCommunityDelay()) : add256(block.number, votingDelay());
        uint endBlock = (emergency == Emergency.Fast) ? add256(startBlock, votingFastPeriod()) : add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.prepareVotes = 0;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.publicityPeriodVotes = 0;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.launchType = launch;
        newProposal.emergencyType = emergency;
        newProposal.canceled = false;
        newProposal.executed = false;

        if(launch == Launch.Foundation) {
            voteProposal.push(newProposal.id);
        }
       
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha: proposal can only be queued if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        if(proposal.emergencyType == Emergency.Normal){
            //通过区块来判断时间   每14s生成一个区块计算 3天约等于18514个区块
            require(block.number > proposal.endBlock + 18514,'not in time');
        } else if(proposal.emergencyType == Emergency.Fast){
            //1天约等于6173个区块
            require(block.number > proposal.endBlock + 6173,'not in time');
        }

        // solhint-disable-next-line not-rely-on-time
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value : proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state = state(proposalId);
        require(state == ProposalState.Active || state == ProposalState.Pending, "GovernorAlpha: can only cancel Active or Pending Proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || tribe.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "GovernorAlpha: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        //todo 获取此提案所在区块总的委托票数
        uint allTickets = 100;
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if ((proposal.launchType == Launch.Foundation && proposal.againstVotes >= div(mul(50,allTickets),100)) || proposal.publicityPeriodVotes >= div(mul(50,allTickets),100)) {
//        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        // solhint-disable-next-line not-rely-on-time
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVotePublicity(uint proposalId,uint amount) public {
        _castVotePublicity(proposalId,amount);
    }

    function _castVotePublicity(uint proposalId,uint amount) internal{
        //todo 校验用户投票权限，获取票数并减去
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        if(proposal.emergencyType == Emergency.Normal){
            //通过区块来判断时间   每14s生成一个区块计算 3天约等于18514个区块
            require(proposal.endBlock < block.number && block.number < proposal.endBlock + 18514,'not in time');
        } else if(proposal.emergencyType == Emergency.Fast){
            //1天约等于6173个区块
            require(proposal.endBlock < block.number && block.number < proposal.endBlock + 6173,'not in time');
        }
        proposal.publicityPeriodVotes = add256(proposal.publicityPeriodVotes, amount);
    }

    function castVotePrepare(uint proposalId,uint amount) public {
         _castVotePrepare(proposalId,amount);
    }

    function _castVotePrepare(uint proposalId,uint amount) internal {
        //todo 校验用户投票权限，获取票数并减去

        //准备期发生在startBlock之前，因此普通成员生成提案的时候 startBlock要写14天之后的blocknumber
        require(state(proposalId) == ProposalState.Pending, "GovernorAlpha: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.launchType == Launch.Community,'this proposal do not vote prepare');
        //todo 这里检测是否已经在准备期通过了，通过了就没必要再投了 100换成5%
        require(proposal.prepareVotes <= 100 ,'already agree');
        proposal.prepareVotes = add256(proposal.prepareVotes, amount);
        //todo 检测是否过了总票数的5% 如果过了 加入排队数组 100换成5%
        if(proposal.prepareVotes > 100 ) {
            voteProposal.push(proposalId);
        }
    }

    function castVote(uint proposalId, bool support,uint amount) public {
        return _castVote(msg.sender, proposalId, support, amount);
    }

//    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
//        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
//        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
//        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
//        address signatory = ecrecover(digest, v, r, s);
//        require(signatory != address(0), "GovernorAlpha: invalid signature");
//        return _castVote(signatory, proposalId, support);
//    }

    function _castVote(address voter, uint proposalId, bool support,uint amount) internal {
        //检测是否可以进行公投
        //1.社区发起的提案是否过了准备期，并且是否是在votePrepare数组的第一位
        //2.基金会发起的提案是否是紧急提案，为紧急提案才可投票，不是紧急提案需要看是否是在数组votePrepare第一位


        require(state(proposalId) == ProposalState.Active, "GovernorAlpha: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];

        if(proposal.emergencyType == Emergency.Normal) {
            //如果第一位的已经不在投票期了。此时还在占位，就看第2位的状况，如果可以删掉第一位
            if(state(voteProposal[0]) != ProposalState.Active){
                require(voteProposal[1] == proposalId,'in queue');
                delete voteProposal[0];
            }else{
                //第一位还在投票期
                require(voteProposal[0] == proposalId ,'in queue');
            }
        }

        //todo 能否重复投
        require(receipt.hasVoted == false, "GovernorAlpha: voter already voted");
//        uint96 votes = tribe.getPriorVotes(voter, proposal.startBlock);
        //todo 校验票数并减去
        if(proposal.launchType == Launch.Foundation) require(support == false ,'foundation must against');
        if (support) {
            proposal.forVotes = add256(proposal.forVotes, amount);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, amount);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = amount;

        emit VoteCast(voter, proposalId, support, amount);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorAlpha: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorAlpha: sender must be gov guardian");
        guardian = address(0);
    }

    function __transferGuardian(address newGuardian) public {
        require(msg.sender == guardian, "GovernorAlpha: sender must be gov guardian");
        guardian = newGuardian;
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorAlpha: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorAlpha: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: div overflow");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    // solhint-disable-next-line func-name-mixedcase
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface TribeInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}
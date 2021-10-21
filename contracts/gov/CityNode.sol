pragma solidity ^0.8.0;

import '../interface/gov/ICityNode.sol';

import '../interface/gov/IParliament.sol';
import '../interface/gov/IGovernanceCommittee.sol';
import '../interface/gov/IBlockNumber.sol';
 import '../interface/gov/ICityNodeFundManagement.sol';
 import '../interface/gov/INewFundManagement.sol';
//import './CityNodeFundManagement.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

//import {PublicStructs} from '../utils/PublicStructs.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import "../lib/TransferHelper.sol";

import '../ref/VoteIdRef.sol';
import "../ref/CoreRef.sol";
import "../interface/token721/IGovernance721.sol";


contract CityNode is ICityNode,CoreRef,IParliament,VoteIdRef,IBlockNumber {

    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;

    struct parliamentData {
        EnumerableSet.AddressSet parliament; //parliament
        uint expireTime;
        bool votePeriod; //Is it during the voting period
        uint impeachIndex; //On which serial number is impeachment
    }

    struct memberData {
        EnumerableSet.AddressSet member; //node's member
        mapping(address => uint) joinTime;
    }

    struct cityNode {
        uint id;
        address manager;  //citynode 's manager
        uint creationTime;
        uint voteId;  // this node's current voteId
        parliamentData parliaments;
        memberData members;
        uint expireTime;
        string name;
        bool active;
        bool firstActive;
        bool votePeriod;//Is it during the voting period
        uint ElfUperCount; //Quantity above Elf
        address cfm; //Fund management contract
        uint proposalBlockNumber;
        uint cityId;
    }

    struct applyRecord {
        address account;
        uint tokenId;
    }
      struct parliamentApply {
        address account;
        uint tickets;
    }
    //Number of city nodes
    uint public cityNodeCount;
    //Address of voting contract
    address public voteAddr;
    //Which node is the user on
    mapping(address => uint) public  userNode; //user in where node

    //Node details
    mapping(uint => cityNode) private cityNodes;

    //People above Elf before activation
    mapping(uint => address[]) public beforeActiveElf;
    //Campaign manager voting records
    mapping(uint => mapping(uint => mapping(address => uint))) public voteRecords;

    //User application administrator record
    mapping(uint => mapping(uint => applyRecord[])) public userApplyRecords;

    mapping(uint => mapping(uint => parliamentApply[])) public parliamentApplyRecords;

    //Current multi sign voting ID record in node
    mapping(uint => uint) public nodeParliamentVoteId;

    mapping(uint => uint[]) public cityGovNodes; //An array of city node IDs contained by the city governance committee

    mapping(uint => mapping(uint =>mapping(address => bool))) public parliamentUp; //Impeachment pending verification
    address public cityGovernanceAddr;



    IGovernance721 public Gov721;
    INewFundManagement public NewFundManagement;

    //The city node verifies the public key address required by the city
    bytes32  private  secret;

    //    mapping(uint => mapping(uint => uint)) public impeachIndex;

    event cityNodeCreate(uint id, address manager, uint creationTime);

    event lengthenManager(uint id, address sender, uint creationTime);

    modifier _onlyVote(address sender) {
        require(sender == voteAddr, "sender is not vote");
        _;
    }




    constructor(address core,address voteIdAddr) public  CoreRef(core)  VoteIdRef(voteIdAddr) {}

    /*
          @dev Verify that a node exists
          @params nodeId
          @return  bool
      */
    function existsCityNode(uint nodeId) public view override returns (bool){
        return cityNodes[nodeId].id != 0;
    }
    /*
          @dev Verify whether it exists in the node
          @params nodeId
          @params sender caller
          @return  bool
      */
    function inNode(uint nodeId, address sender) public view override returns (bool) {
        //        require(userNode[sender] == nodeId, "not in");
        return userNode[sender] == nodeId;
    }
    function getUserNode(address sender) external view override returns(uint) {
        return userNode[sender];
    }

     function setVote(address addr) public  onlyGovernor() {
        voteAddr = addr;
    }

    function setGov721(address addr) public onlyGovernor() {
        Gov721 = IGovernance721(addr);
    }

    function setNewFundManagement(address addr) public onlyGovernor(){
        NewFundManagement = INewFundManagement(addr);
    }
    /*
      @dev Get the voting block of the current node
  */
    function getBlockNumber(uint id) external override view returns(uint) {
        return cityNodes[id].proposalBlockNumber;
    }

    /*
          @dev Get node details
          @params nodeId
          @return node details
      */
    function getCityNodeInfo(uint nodeId) external view override returns (bool, uint, address, uint) {
        return (cityNodes[nodeId].votePeriod, cityNodes[nodeId].expireTime, cityNodes[nodeId].manager, cityNodes[nodeId].voteId);
    }

    /*

    */

    function _destroyGovToken(uint tokenId) internal {
        require(Gov721.expire(tokenId) > block.timestamp,'NFTtoken  is expired');
        require(Gov721.ownerOf(tokenId) == msg.sender,'no access');
        Gov721.safeTransferFrom(msg.sender,address(0),tokenId);
    }

    /*
       @dev create node
       @params tokenId City node token ID
   */
    function createNode(uint tokenId,string memory name, bytes32  hash,uint y,uint a) external override {
        //todo for test close
        require(hash ==  keccak256(abi.encodePacked(y, a, secret)));
        _destroyGovToken(tokenId);
        cityNodeCount++;
        NewFundManagement.newInit();
        cityNode storage c = cityNodes[cityNodeCount];
        c.id = cityNodeCount;
        c.manager = msg.sender;
        c.creationTime = block.timestamp;
        c.voteId = IVoteId(voteIdAddress).incrVoteId();
        c.active = false;
        c.firstActive = false;
        c.cfm =  NewFundManagement.newInit();
        c.name = name;
        c.votePeriod = false;
        c.proposalBlockNumber = block.timestamp;
        c.cityId = y;

        cityGovNodes[c.cityId].push(c.id);
        if(cityGovNodes[c.cityId].length == 10){
            IGovernanceCommittee(cityGovernanceAddr).newGovernanceCommittee(c.cityId,a);
        }
        userNode[msg.sender] = c.id;

        emit cityNodeCreate(c.id, msg.sender, block.timestamp);
    }

    /*
       @dev Join node
       @params nodeId
      */
    function joinNode(uint nodeId) external override {
        require(userNode[msg.sender] == 0, 'user  exists node');
        require(existsCityNode(nodeId), 'not exists this node');
        //non-existent
        cityNode storage cn = cityNodes[nodeId];
        cn.members.member.add(msg.sender);
        cn.members.joinTime[msg.sender] = block.timestamp;
        //todo Determine whether this person's identity is Elf or above
        userNode[msg.sender] = nodeId;
        bool isElf = true;
        if (isElf) {
            cn.ElfUperCount++;
            //Not activated
            if (cn.firstActive == false && cn.ElfUperCount <= 12) {
                beforeActiveElf[nodeId].push(msg.sender);
            }
            if (cn.ElfUperCount == 12) {
                cn.firstActive = true;
                cn.active == true;
                //todo for test close
                 cn.expireTime = block.timestamp + 90 days;
//                 cn.expireTime = 0;
                //Administrator due 90 days
                //More than 12 parliament took office for the first time
                for (uint i = 0; i < beforeActiveElf[nodeId].length; i++) {
                    cn.parliaments.parliament.add(beforeActiveElf[nodeId][i]);
                    //todo for test close
                     cn.parliaments.expireTime = block.timestamp + 30 days;
//                    cn.parliaments.expireTime = 0;
                    //parliament 30 days overdue
                    cn.parliaments.votePeriod = false;
                    cn.parliaments.impeachIndex = 11;
                }
            }
        }
    }


        /*
    @dev quitNode
    */
    function quitNode() external override {
        require(userNode[msg.sender] != 0, 'user not in  node');
        cityNode storage cn = cityNodes[userNode[msg.sender]];
        cn.members.member.remove(msg.sender);
        cn.members.joinTime[msg.sender] == 0;
        //This person is an administrator. To exit the node, you need to start the campaign
        if(msg.sender == cn.manager) {
            cn.manager =  address(0);
            cn.voteId = IVoteId(voteIdAddress).incrVoteId();
            cn.proposalBlockNumber = block.number;
            cn.votePeriod = true;
        }
        //todo Determine whether this person's identity is Elf or above
        bool isElf = true;
        if (isElf) {
            cn.ElfUperCount--;
            //If it is parliament, delete the parliament
            if (cn.parliaments.parliament.contains(msg.sender)) {
                cn.parliaments.parliament.remove(msg.sender);
            }
        }
    }

    function getCityNodeFMAddress(uint id) public view returns(address){
        return cityNodes[id].cfm;
    }

    function getCityTrueId(uint id) public override view returns(uint) {
        return cityNodes[id].cityId;
    }

    /*
    @dev Continuation administrator
    @params nodeId
    */
    function lengthen(uint nodeId,uint tokenId) external override {
        require(inNode(nodeId, msg.sender), 'not in node');
        cityNode storage cn = cityNodes[nodeId];
        require(msg.sender == cn.manager, 'no access');
        require(cn.expireTime + 7 days > block.timestamp, 'not in time');
        _destroyGovToken(tokenId);
        if (block.timestamp >= cn.expireTime) {
            cn.expireTime = block.timestamp + 30 days;
        } else {
            cn.expireTime = cn.expireTime + 30 days;
        }
        emit lengthenManager(nodeId, msg.sender, block.timestamp);
    }


    /*
    @dev Activating the campaign requires giving certain rewards to the activator
    @params nodeId
    */
    function activeToCampaign(uint nodeId) external override {
        require(inNode(nodeId, msg.sender), 'not in node');
        cityNode storage cn = cityNodes[nodeId];
        require(cn.expireTime + 7 days < block.timestamp, 'not in time');
        require(cn.votePeriod == false,'in votePeriod no access edit');
        cn.manager =  address(0);
        cn.voteId = IVoteId(voteIdAddress).incrVoteId();
        cn.proposalBlockNumber = block.number;
        cn.votePeriod = true;
    }
    /*
  @dev Apply for campaign administrator
  @params nodeId
  @params tokenId

  */
    function applyManager(uint nodeId, uint tokenId) external override {

        require(inNode(nodeId, msg.sender), 'not in node');
        require(cityNodes[nodeId].manager == address(0),'not in time');
//        _destroyGovToken(tokenId);
        require(getExistsApplyUsers(nodeId,cityNodes[nodeId].voteId,msg.sender) == false);
        if(userApplyRecords[nodeId][cityNodes[nodeId].voteId].length < 7 ){
            require(cityNodes[nodeId].expireTime + 7 days < block.timestamp, 'not in time');
        } else {
            require(cityNodes[nodeId].expireTime + 7 days < block.timestamp && cityNodes[nodeId].expireTime + 14 days > block.timestamp, 'not in time');
        }
        applyRecord memory ar = applyRecord({
        account : msg.sender,
        tokenId : tokenId
        });
        userApplyRecords[nodeId][cityNodes[nodeId].voteId].push(ar);
    }


    /*
    @dev Verify whether someone is running for office
    @params nodeId
    @params voteId Voting ID of the current node
    @params applicant ID of the verifier
    @return bool
    */
    function getExistsApplyUsers(uint nodeId, uint voteId, address applicant) public override view returns (bool){
        for (uint i = 0; i < userApplyRecords[nodeId][voteId].length; i++) {
            if (applicant == userApplyRecords[nodeId][voteId][i].account) {
                return true;
            }
        }
        return false;
    }


    /*
    @dev Administrator campaign voting
    @params nodeId
    @params voteId voteId Voting ID of the current node
    @params user People voted
    @params tickets
    */
    function voteToManager(uint nodeId, uint voteId, address user, uint tickets) external override _onlyVote(msg.sender) {
        voteRecords[nodeId][voteId][user] += tickets;
    }

    /*
    @dev End administrator campaign voting
    @params nodeId
    @params voteId voteId voteId Voting ID of the current node

    */
    function endToManager(uint nodeId, uint voteId) external override _onlyVote(msg.sender) {
        require(userApplyRecords[nodeId][voteId].length >= 7,'no have enough people');
        (address winner,uint index) = getWinner(nodeId, voteId);
        cityNode storage cn = cityNodes[nodeId];
        cn.votePeriod = false;
        cn.manager = winner;
        cn.expireTime = block.timestamp + 90 days;
        if (cn.parliaments.parliament.contains(winner)) {
            cn.parliaments.parliament.remove(winner);
        }
        for (uint i = 0; i < userApplyRecords[nodeId][voteId].length; i++) {
            address user = userApplyRecords[nodeId][voteId][i].account;
            if (i != index) {
                //todo 721token transfer return user's token
            }
        }
        // cn.voteId++;
    }
    /*
        @dev Gets the current winner of the administrator's campaign round
        @params nodeId
        @params voteId  Voting ID of the current node
        @return Winner's address and index
    */
    function getWinner(uint nodeId, uint voteId) public view returns (address, uint){
        uint max = 1;
        uint index;
        address winner = address(0);
        for (uint i = 0; i < userApplyRecords[nodeId][voteId].length; i++) {
            address user = userApplyRecords[nodeId][voteId][i].account;
            if (voteRecords[nodeId][voteId][user] > max) {
                winner = user;
                max = voteRecords[nodeId][voteId][user];
                index = i;
            }
        }
        return (winner, index);
    }

    /*
        @dev Activate the campaign for parliamentary membership
        @params nodeId
    */
    function activeToParliaments(uint nodeId) external {
        require(inNode(nodeId, msg.sender), 'not in node');
        cityNode storage cn = cityNodes[nodeId];
        require(cn.parliaments.expireTime < block.timestamp);
        require(cn.parliaments.votePeriod == false);
        //Delete the previous
        uint parliamentLength = cn.parliaments.parliament.length();
        for (uint i = 0; i < parliamentLength; i++) {
            address user = cn.parliaments.parliament.at(i);
            cn.parliaments.parliament.remove(user);
        }
        cn.parliaments.votePeriod = true;
        nodeParliamentVoteId[nodeId] =  IVoteId(voteIdAddress).incrVoteId();
    }

    function getParliamentLength(uint id) public view returns(uint){
          cityNode storage cn = cityNodes[id];
          return cn.parliaments.parliament.length();
    }

    function getParliamentByIndex(uint id,uint i) public view returns(address){
         cityNode storage cn = cityNodes[id];
         return cn.parliaments.parliament.at(i);
    }

        /*
    @dev Apply for multiple signatures
    @params nodeId

    */
    function applyParliament(uint nodeId) external override {
        require(inNode(nodeId, msg.sender), 'not in node');
        //todo Judge whether it is a community Elf or above



        cityNode storage cn = cityNodes[nodeId];

        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,cn.cfm,1000 * 10 ** 18);
        ICityNodeFundManagement(cn.cfm).addTokenStorage('PUBLIC_STORE',address(Rbt()),1000 * 10 ** 18);
        require(cn.parliaments.votePeriod == true);
        uint length = parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]].length;
        if (length < 15) {
            require(cn.parliaments.expireTime < block.timestamp, 'not in time');
        } else {
            require(cn.parliaments.expireTime < block.timestamp && cn.parliaments.expireTime + 7 days > block.timestamp, 'not in time');
        }

        _setParliamentApply(nodeId,nodeParliamentVoteId[nodeId],msg.sender,0);
    }

         /*
        @dev Set application information
    */
    function _setParliamentApply(uint id, uint voteId,address sender,uint tickets) internal  {
        parliamentApply memory ar = parliamentApply({
            account : msg.sender,
            tickets : 0
        });
        parliamentApplyRecords[id][voteId].push(ar);
    }



    /*
    @dev Get the number of campaign signatures and information
    @params nodeId
    @params voteId Voting ID of the current node
    @return Number of people
    */
    function getApplyParliament(uint nodeId, uint voteId) public view override returns (uint){
        uint length = parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]].length;
        return length;
    }

    /*
  @dev Get the campaign ID of the current parliament
  @params nodeId
  @return ID
  */
    function getApplyParliamentVoteId(uint nodeId) external view override returns (uint){
        return nodeParliamentVoteId[nodeId];
    }

    /*
  @dev parliament campaign voting
  @params nodeId
  @params voteId Voting ID of the current node
  @params user to user
  @params tickets
  */

    function voteToParliament(uint nodeId, uint voteId, address user, uint tickets) external override _onlyVote(msg.sender) {
        require(voteId == nodeParliamentVoteId[nodeId]);
        (uint length) = getApplyParliament(nodeId, voteId);
        bool existsUser = false;
        for (uint i = 0; i < length; i++) {
            if (user == parliamentApplyRecords[nodeId][voteId][i].account) {
                existsUser = true;
                parliamentApplyRecords[nodeId][voteId][i].tickets += (tickets);
                break;
            }
        }
        require(existsUser == true);
    }

    /*
 @dev End administrator campaign voting
 @params nodeId
 @params voteId Voting ID of the current node

 */

    function endToParliament(uint nodeId, uint voteId) external override _onlyVote(msg.sender) {
     cityNode storage cn = cityNodes[nodeId];
        (uint length) = getApplyParliament(nodeId, voteId);
             require(length >=15 ,'not enough people');
        require( cn.parliaments.votePeriod == true);
        _quickSort(parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]], 0, length);

        cn.parliaments.votePeriod = false;
        cn.parliaments.expireTime = block.timestamp + 30 days;
        // parliaments 30 days overdue
        for (uint i = 0; i < 12; i++) {
            cn.parliaments.parliament.add(parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]][i].account);
        }
        if (length > 12) {
            for (uint i = 12; i < length; i++) {
                address user = parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]][i].account;
                 IERC20 rbt = core().rbt();
                TransferHelper.safeTransferFrom(address(rbt),cn.cfm,msg.sender,1000 * 10 ** 18);
            }
        }
    }

    /*
     @dev Setting up members of Parliament
     @params nodeid
     @params voteId Which vote
     @params index Member serial number
    */
    function setParliament(uint nodeId, uint voteId, uint index) external override _onlyVote(msg.sender) {
        address user = parliamentApplyRecords[nodeId][voteId][index].account;
        parliamentUp[nodeId][voteId][user] = true;
//        cityNodes[nodeId].parliaments.parliament.add(user);
        cityNodes[nodeId].parliaments.impeachIndex++;
    }

    /*
        @dev The one who takes advantage of the situation will pay again
    */
    function parliamentTakeOffice(uint nodeId) public {
        cityNode storage cn = cityNodes[nodeId];
        require(parliamentUp[nodeId][cn.voteId][msg.sender],'no access');
        require( IERC20( address(Rbt())).balanceOf(msg.sender) >= 1000 * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,cn.cfm,1000 * 10 ** 18);
        cityNodes[nodeId].parliaments.parliament.add(msg.sender);
    }


    /*
         @dev Delete a member of Parliament
         @params nodeid
         @params user Address of members of Parliament

     */
    function removeParliament(uint nodeId, address user) external override _onlyVote(msg.sender) {
        cityNodes[nodeId].parliaments.parliament.remove(user);
    }

    /*
          @dev See if someone exists in Parliament
          @params nodeId
          @return bool
      */
    function hasParliament(uint nodeId, address user) external override view returns (bool){
        return cityNodes[nodeId].parliaments.parliament.contains(user);
    }

    /*
        @dev Get details of Parliament
        @params nodeId
        @return Expiration time, whether it is in the voting period, impeachment sequence
    */
    function parliamentInfo(uint nodeId) external override view returns (uint, bool, uint){
        return (cityNodes[nodeId].parliaments.expireTime, cityNodes[nodeId].parliaments.votePeriod, cityNodes[nodeId].parliaments.impeachIndex);
    }

    /*
        @dev Receive their own dividends
    */
    function receiveReward(uint nodeId,address token,uint amount) external  {
          address cfm = cityNodes[nodeId].cfm;
        require(ICityNodeFundManagement(cfm).getUserReward(msg.sender,token) >= amount,'not enough');

        ICityNodeFundManagement(cfm).setUserReward(msg.sender,token,amount,2);
         TransferHelper.safeTransferFrom(token,cfm,msg.sender,amount);
    }



    /*
        @dev Payment of impeachment reward
        @params nodeId
        @params voteId Voting ID of the current node
    */

    function impeachExtract(uint nodeId, address token, uint amount, address receiver, uint impeachType) external override _onlyVote(msg.sender) {
        address cfm = cityNodes[nodeId].cfm;
        ICityNodeFundManagement(cfm).impeachTokenSend(receiver, amount, token, impeachType);
    }




    /*
        @dev Set the node administrator by voting
        @params nodeId
        @params manager

    */
    function setManagerInfo(uint nodeId, address manager) external override _onlyVote(msg.sender) {
        cityNodes[nodeId].manager = manager;
    }

    function getNodeCityGov(uint nodeId) external override view returns(uint) {
        return cityNodes[nodeId].cityId;
    }


    /*
        @dev Quickly sort the voting results produced by Parliament from large to small
        @params arr Array of parliamentary applications
        @params left   Array left
        @params right  Array right
    */

    function _quickSort(parliamentApply[] storage arr, uint left, uint right) internal {
        uint i = left;
        uint j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].tickets;
        while (i <= j) {
            while (arr[uint(i)].tickets < pivot) i++;
            while (pivot < arr[uint(j)].tickets) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSort(arr, left, j);
        if (i < right)
            _quickSort(arr, i, right);
    }
}

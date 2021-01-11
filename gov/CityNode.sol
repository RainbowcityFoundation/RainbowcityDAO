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
        EnumerableSet.AddressSet parliament; //多签
        uint expireTime;
        bool votePeriod; //是否在多签投票期间
        uint impeachIndex; //弹劾在哪个序号上
    }

    struct memberData {
        EnumerableSet.AddressSet member; //成员
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
        bool votePeriod;//是否在投票期间
        uint ElfUperCount; //精灵以上数量
        address cfm; //资金管理合约
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
    //城市节点数量
    uint public cityNodeCount;
    //投票合约的地址
    address public voteAddr;
    //用户在哪个节点
    mapping(address => uint) public  userNode; //user in where node

    //节点详细信息
    mapping(uint => cityNode) private cityNodes;

    //在激活之前精灵以上的人
    mapping(uint => address[]) public beforeActiveElf;
    //竞选管理员投票记录
    mapping(uint => mapping(uint => mapping(address => uint))) public voteRecords;

    //用户申请竞选管理员记录
    mapping(uint => mapping(uint => applyRecord[])) public userApplyRecords;

    mapping(uint => mapping(uint => parliamentApply[])) public parliamentApplyRecords;

    //节点中的当前多签投票ID记录
    mapping(uint => uint) public nodeParliamentVoteId;

    mapping(uint => uint[]) public cityGovNodes; //城市治理委员会所包含的城市节点ID数组

    mapping(uint => mapping(uint =>mapping(address => bool))) public parliamentUp; //弹劾待上位验证
    address public cityGovernanceAddr;



    IGovernance721 public Gov721;
INewFundManagement public NewFundManagement;

    //城市节点验证城市所需公钥地址
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
          @dev 验证某个节点是否存在
          @params nodeId 节点ID
          @return  bool 存在返还true
      */
    function existsCityNode(uint nodeId) public view override returns (bool){
        return cityNodes[nodeId].id != 0;
    }
    /*
          @dev 验证是否是存在节点里
          @params nodeId 节点ID
          @params sender 调用者
          @return  bool 存在返还true
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
      @dev 获取当前节点的投票所处区块
  */
    function getBlockNumber(uint id) external override view returns(uint) {
        return cityNodes[id].proposalBlockNumber;
    }

    /*
          @dev 获取节点详细信息
          @params nodeId 节点ID
          @return 节点详细信息
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
       @dev 加入节点
       @params tokenId 城市节点令牌ID
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

    // function verifySign(bytes32  hash,uint8 v, bytes32 r, bytes32 s) public view returns (address){
  
    //     // bytes32  r = bytesToBytes32(slice(signedString, 0, 32));
    //     // bytes32  s = bytesToBytes32(slice(signedString, 32, 32));
    //     // byte  v1 = slice(signedString, 64, 1)[0];
    //     // uint8 v = uint8(v1) + 27;
    //     return ecrecoverDecode(hash, r, s, v);
    // }

    //使用ecrecover恢复公匙
//    function ecrecoverDecode(bytes32  hash,bytes32 r, bytes32 s, uint8 v) public view returns (address addr){
//       addr = ecrecover(hash, v, r, s);
//    }

      //function sliceBytes(string)

    //将原始数据按段切割出来指定长度
    // function slice(bytes memory data, uint start, uint len) returns (bytes){
    //     bytes memory b = new bytes(len);
    
    //     for(uint i = 0; i < len; i++){
    //       b[i] = data[i + start];
    //     }
    //     return b;
    // }
    /*
       @dev 加入节点
       @params nodeId 节点ID
      */
    function joinNode(uint nodeId) external override {
        require(userNode[msg.sender] == 0, 'user  exists node');
        require(existsCityNode(nodeId), 'not exists this node');
        //不存在
        cityNode storage cn = cityNodes[nodeId];
        cn.members.member.add(msg.sender);
        cn.members.joinTime[msg.sender] = block.timestamp;
        //todo 判断此人身份是否精灵以及以上
        userNode[msg.sender] = nodeId;
        bool isElf = true;
        if (isElf) {
            cn.ElfUperCount++;
            //没有激活过
            if (cn.firstActive == false && cn.ElfUperCount <= 12) {
                beforeActiveElf[nodeId].push(msg.sender);
            }
            if (cn.ElfUperCount == 12) {
                cn.firstActive = true;
                cn.active == true;
                //todo for test close
                 cn.expireTime = block.timestamp + 90 days;
//                 cn.expireTime = 0;
                //管理员90天到期
                //12个多签首次上任
                for (uint i = 0; i < beforeActiveElf[nodeId].length; i++) {
                    cn.parliaments.parliament.add(beforeActiveElf[nodeId][i]);
                    //todo for test close
                     cn.parliaments.expireTime = block.timestamp + 30 days;
//                    cn.parliaments.expireTime = 0;
                    //多签30天到期
                    cn.parliaments.votePeriod = false;
                    cn.parliaments.impeachIndex = 11;
                }
            }
        }
    }


    /*
@dev 退出节点
*/
    function quitNode() external override {
        require(userNode[msg.sender] != 0, 'user not in  node');
        cityNode storage cn = cityNodes[userNode[msg.sender]];
        cn.members.member.remove(msg.sender);
        cn.members.joinTime[msg.sender] == 0;
        //此人是管理员，退出节点，需要开启竞选
        if(msg.sender == cn.manager) {
            cn.manager =  address(0);
            cn.voteId = IVoteId(voteIdAddress).incrVoteId();
            cn.proposalBlockNumber = block.number;
            cn.votePeriod = true;
        }
        //todo 判断此人身份是否精灵以及以上
        bool isElf = true;
        if (isElf) {
            cn.ElfUperCount--;
            //如果是多签，删除多签
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
    @dev 延续管理员
    @params nodeId 节点ID
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
    @dev 激活竞选  需要给激活人一定的奖励
    @params nodeId 节点ID
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
  @dev /申请竞选管理员
  @params nodeId 节点ID
  @params tokenId 城市节点令牌id

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
    @dev /验证是否某人参加了竞选
    @params nodeId 节点ID
    @params voteId 当前节点的投票ID
    @params applicant 验证人的Id
    @return bool 存在返还true
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
    @dev /管理员竞选投票
    @params nodeId 节点ID
    @params voteId 当前节点的投票ID
    @params user 投给谁
    @params tickets 投几票
    */
    function voteToManager(uint nodeId, uint voteId, address user, uint tickets) external override _onlyVote(msg.sender) {
        voteRecords[nodeId][voteId][user] += tickets;
    }

    /*
    @dev 结束管理员竞选投票
    @params nodeId 节点ID
    @params voteId 当前节点的投票ID

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
                //todo 721token转账 返还用户的token
            }
        }
        // cn.voteId++;
    }
    /*
        @dev 获取管理员竞选一轮投票中 截止当前的胜者
        @params nodeId 节点ID
        @params voteId 当前节点的投票ID
        @return 获胜者的地址 以及 索引
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
        @dev 激活竞选议会成员
        @params nodeId 节点ID
    */
    function activeToParliaments(uint nodeId) external {
        require(inNode(nodeId, msg.sender), 'not in node');
        cityNode storage cn = cityNodes[nodeId];
        require(cn.parliaments.expireTime < block.timestamp);
        require(cn.parliaments.votePeriod == false);
        //将之前的删掉
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
@dev /申请竞选多签
@params nodeId 节点ID

*/
    function applyParliament(uint nodeId) external override {
        require(inNode(nodeId, msg.sender), 'not in node');
        //todo 判断是否是社区精灵及以上

     
        
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
        @dev 设置申请信息
    */
    function _setParliamentApply(uint id, uint voteId,address sender,uint tickets) internal  {
        parliamentApply memory ar = parliamentApply({
            account : msg.sender,
            tickets : 0
        });
        parliamentApplyRecords[id][voteId].push(ar);
    }

    /*
    @dev /多签竞选投票
    @params nodeId 节点ID
    @params voteId 当前的投票ID
    @params user 投给谁
    @params tickets 投几票
    */
    // function voteToParliament(uint nodeId,uint voteId,address user,uint tickets) external override _onlyVote(msg.sender) {
    //     voteRecords[nodeId][voteId][user]+= tickets;
    // }

    /*
    @dev /获取竞选多签的人数以及信息
    @params nodeId 节点ID
    @params voteId 当前的投票ID
    @return 人数
    */
    function getApplyParliament(uint nodeId, uint voteId) public view override returns (uint){
        uint length = parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]].length;
        return length;
    }

    /*
  @dev /获取当前duoqian的竞选ID
  @params nodeId 节点ID
  @return ID
  */
    function getApplyParliamentVoteId(uint nodeId) external view override returns (uint){
        return nodeParliamentVoteId[nodeId];
    }

    /*
  @dev /多签竞选投票
  @params nodeId 节点ID
  @params voteId 当前节点的投票ID
  @params user 投给谁
  @params tickets 投几票
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
 @dev 结束管理员竞选投票
 @params nodeId 节点ID
 @params voteId 当前节点的投票ID

 */

    function endToParliament(uint nodeId, uint voteId) external override _onlyVote(msg.sender) {
     cityNode storage cn = cityNodes[nodeId];
        (uint length) = getApplyParliament(nodeId, voteId);
             require(length >=15 ,'not enough people');
        require( cn.parliaments.votePeriod == true);
        _quickSort(parliamentApplyRecords[nodeId][nodeParliamentVoteId[nodeId]], 0, length);
      
        cn.parliaments.votePeriod = false;
        cn.parliaments.expireTime = block.timestamp + 30 days;
        //多签30天到期
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
     @dev 设置议会成员
     @params nodeid 节点id
     @params voteId 哪次投票产生的
     @params index 成员序号
    */
    function setParliament(uint nodeId, uint voteId, uint index) external override _onlyVote(msg.sender) {
        address user = parliamentApplyRecords[nodeId][voteId][index].account;
        parliamentUp[nodeId][voteId][user] = true;
//        cityNodes[nodeId].parliaments.parliament.add(user);
        cityNodes[nodeId].parliaments.impeachIndex++;
    }

    /*
        @dev顺势上位的那个交钱再上
    */
    function parliamentTakeOffice(uint nodeId) public {
        cityNode storage cn = cityNodes[nodeId];
        require(parliamentUp[nodeId][cn.voteId][msg.sender],'no access');
        require( IERC20( address(Rbt())).balanceOf(msg.sender) >= 1000 * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,cn.cfm,1000 * 10 ** 18);
        cityNodes[nodeId].parliaments.parliament.add(msg.sender);
    }


    /*
         @dev 删除某个议会成员
         @params nodeid 节点id
         @params user 议会成员地址

     */
    function removeParliament(uint nodeId, address user) external override _onlyVote(msg.sender) {
        cityNodes[nodeId].parliaments.parliament.remove(user);
    }

    /*
          @dev 查看议会是否存在某人
          @params 节点id
          @return 是true 否 false
      */
    function hasParliament(uint nodeId, address user) external override view returns (bool){
        return cityNodes[nodeId].parliaments.parliament.contains(user);
    }

    /*
        @dev 获取议会的详情
        @params 节点id
        @return 到期时间，是否在投票期，弹劾序列
    */
    function parliamentInfo(uint nodeId) external override view returns (uint, bool, uint){
        return (cityNodes[nodeId].parliaments.expireTime, cityNodes[nodeId].parliaments.votePeriod, cityNodes[nodeId].parliaments.impeachIndex);
    }

    /*
        @dev 领取属于自己的分红
    */
    function receiveReward(uint nodeId,address token,uint amount) external  {
          address cfm = cityNodes[nodeId].cfm;
        require(ICityNodeFundManagement(cfm).getUserReward(msg.sender,token) >= amount,'not enough');

        ICityNodeFundManagement(cfm).setUserReward(msg.sender,token,amount,2);
         TransferHelper.safeTransferFrom(token,cfm,msg.sender,amount);
    }



    /*
        @dev 弹劾的赏金发放
        @params nodeId 节点ID
        @params voteId 当前节点的投票ID
    */

    function impeachExtract(uint nodeId, address token, uint amount, address receiver, uint impeachType) external override _onlyVote(msg.sender) {
        address cfm = cityNodes[nodeId].cfm;
        ICityNodeFundManagement(cfm).impeachTokenSend(receiver, amount, token, impeachType);
    }




    /*
        @dev 设置节点管理员，通过投票来设置
        @params 节点ID
        @params 节点管理员

    */
    function setManagerInfo(uint nodeId, address manager) external override _onlyVote(msg.sender) {
        cityNodes[nodeId].manager = manager;
    }

    function getNodeCityGov(uint nodeId) external override view returns(uint) {
        return cityNodes[nodeId].cityId;
    }


    /*
        @dev 对议会产生的投票结果进行快速排序 按票数从大到小
        @params arr 议会申请的数组
        @params left 左边
        @params right 右边
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

    //bytes转换为bytes32
    // function bytesToBytes32(bytes memory source) public returns (bytes32 result) {
    //     assembly {
    //         result := mload(add(source, 32))
    //     }
    // }
}

pragma solidity ^0.8.0;
import './CityNodeRef.sol';
import "../ref/CoreRef.sol";
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../interface/gov/IGovernanceCommittee.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../interface/gov/IGlobalGovernanceCommittee.sol';
import '../ref/VoteIdRef.sol';
import '../interface/gov/IParliament.sol';
import '../interface/gov/ICityGovCommittee.sol';
import '../interface/gov/IBlockNumber.sol';
import './CityNodeFundManagement.sol';
contract AreaGovernanceCommittee  is CityNodeRef,CoreRef,IGovernanceCommittee,VoteIdRef,IParliament,IBlockNumber {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    constructor(address nodeAddress,address core,address voteIdAddr) public  CityNodeRef(nodeAddress)  CoreRef(core) VoteIdRef(voteIdAddr)  {}
    struct cityGovernance{
        uint id;
        uint  areaId;
        address manager;
        uint creationTime;
        uint proposalBlockNumber;
        address cfm;
    }
    struct parliamentData {
        EnumerableSet.AddressSet parliament;
        uint  expireTime;
        bool votePeriod;
        uint voteId;
        uint impeachIndex;
    }


    struct parliamentApply {
        address account;
        uint tickets;
    }
    uint public govCount;

    mapping(uint => parliamentData ) private govParliament;

    mapping(uint => cityGovernance) public cityGovernances;

    event cityGovernanceCreate(uint id, uint adreaId, uint creationTime);

    mapping(uint => mapping(uint => parliamentApply[])) public parliamentApplyRecords;

    mapping(bytes32 => uint) public cityGovernancesBonus;  //每个委员会分红记账

    mapping(address =>mapping(address => uint) ) public parliamentReward;
    
    mapping(uint => mapping(address => uint)) govTokenAmount; //各个治理委员会的代币余额


    mapping(uint => mapping(uint =>mapping(address => bool))) public parliamentUp; //弹劾待上位验证
    address public global;

    address public cityGov;


    modifier _inCityGov(uint cityGovId,address sender) {
        require(inNode(cityGovId,sender) == true,'not in');
        _;
    }

    function setGlobalGov(address globalGov) public  onlyGovernor {
         global = globalGov;
    }

    function inNode(uint areaGovId, address sender) public view override returns (bool) {
        uint nodeId = cityNode.getUserNode(sender);
        //获取城市节点的所属城市委员会，
        uint cityId = cityNode.getCityTrueId(nodeId);
        uint adreaId =  ICityGovCommittee(cityGov).getAreaIdByCityId(cityId);

        return (cityGovernances[areaGovId].areaId == adreaId);
    }


    /*
        @dev 生成新的城市治理委员会
        @params 城市hash
    */
    function newGovernanceCommittee (uint id,uint area) external override {
        govCount++;
        cityGovernance storage c = cityGovernances[govCount];
        c.id = govCount;
        c.creationTime = block.timestamp;

        c.areaId = id; //真实城市治理的iD
        // c.proposalBlockNumber = block.timestamp;
        CityNodeFundManagement _cfm = new CityNodeFundManagement(address(this),address(core()),address(Rbt()));
        c.cfm = address(_cfm);
        //todo 根据实际情况设置
        if(govCount == 13) {
            IGlobalGovernanceCommittee(global).activeGov();
        }
        emit cityGovernanceCreate(c.id,id,block.timestamp);
    }

    /*
        @dev 开启投票
        @params id 某个委员会的id

    */

    function activeToParliaments(uint id) public _inCityGov(id,msg.sender){
        // require(inNode(nodeId, msg.sender), 'not in node');
        require(govParliament[id].expireTime < block.timestamp);
        require(govParliament[id].votePeriod == false);
        _startVoteParliament(id);
    }

    /*
        @dev 获取当前节点的投票所处区块
    */
    function getBlockNumber(uint id) external override view returns(uint) {
        return cityGovernances[id].proposalBlockNumber;
    }

    /*
     @dev 开启投票
     @params id 某个委员会的id

 */
    function applyParliament(uint id) external override   _inCityGov(id,msg.sender){
        //        require(inNode(nodeId, msg.sender), 'not in node');
        //todo 判断是否是社区精灵及以上
        require( IERC20( address(Rbt())).balanceOf(msg.sender) >= 1000 * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,cityGovernances[id].cfm,1000 * 10 ** 18);

        require(govParliament[id].votePeriod == true);
        uint length = parliamentApplyRecords[id][govParliament[id].voteId].length;
        if (length < 15) {
            require(govParliament[id].expireTime < block.timestamp, 'not in time');
        } else {
            require(govParliament[id].expireTime < block.timestamp && govParliament[id].expireTime + 7 days > block.timestamp, 'not in time');
        }

        _setParliamentApply(id,govParliament[id].voteId,msg.sender,0);
    }

    /*

    */
    //todo 调用core验证来源
    function operateUserReward(address user,address token,uint mold,uint amount) public {
        require(mold == 1 || mold == 2,'not access');
        if (mold == 1) {
            parliamentReward[user][token] =  parliamentReward[user][token].add(amount);
        }else if(mold == 2){
            parliamentReward[user][token] =  parliamentReward[user][token].sub(amount);
        }
    }

  /*
        @dev /获取竞选多签的人数以及信息
        @params nodeId 节点ID
        @params voteId 当前的投票ID
        @return 人数
    */
    function getApplyParliament(uint id, uint voteId) public view override returns (uint){
        uint length = parliamentApplyRecords[id][voteId].length;
        return length;
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
    
      function getApplyParliamentVoteId(uint id) external  view override   returns (uint){
        return govParliament[id].voteId;
    }
      function getCityNodeInfo(uint id) external view override returns (bool, uint, address, uint) {
        return (govParliament[id].votePeriod, govParliament[id].expireTime, cityGovernances[id].manager,govParliament[id].voteId);
    }
    
    
     /*
       @dev 弹劾的赏金发放
       @params nodeId 节点ID
       @params voteId 当前节点的投票ID
    */

    function impeachExtract(uint nodeId, address token, uint amount, address receiver, uint impeach) external override onlyVote{
        require(govTokenAmount[nodeId][token] >= amount,'not enough token');
        govTokenAmount[nodeId][token] = govTokenAmount[nodeId][token].sub(amount);
        _extract(receiver,amount,token);
    }
     function parliamentInfo(uint nodeId) external view override  returns (uint, bool, uint){
        return (govParliament[nodeId].expireTime, govParliament[nodeId].votePeriod, govParliament[nodeId].impeachIndex);
    }
    
    
    /*
     @dev 删除某个议会成员
     @params nodeid 节点id
     @params user 议会成员地址

 */

    function removeParliament(uint nodeId, address user) external override  onlyVote{
        govParliament[nodeId].parliament.remove(user);
    }
    
      function _extract(address receiver,uint  amount,address token) internal {
        IERC20(token).transfer(receiver,amount);
    }
    
       /*
     @dev 设置节点管理员，通过投票来设置
     @params 节点ID
     @params 节点管理员

 */

    function setManagerInfo(uint nodeId, address manager) external override onlyVote{
        cityGovernances[nodeId].manager = manager;
    }
    
    
      /*
   @dev 设置议会成员
   @params nodeid 节点id
   @params voteId 哪次投票产生的
   @params index 成员序号
  */
    function setParliament(uint nodeId, uint voteId, uint index) external override  onlyVote{
        address user = parliamentApplyRecords[nodeId][voteId][index].account;
//        govParliament[nodeId].parliament.add(user);
        parliamentUp[nodeId][voteId][user] = true;
        govParliament[nodeId].impeachIndex++;
    }



    /*
   @dev顺势上位的那个交钱再上
*/
    function parliamentTakeOffice(uint nodeId) public {
        require(parliamentUp[nodeId][govParliament[nodeId].voteId][msg.sender],'no access');
        require( IERC20( address(Rbt())).balanceOf(msg.sender) >= 1000 * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,cityGovernances[nodeId].cfm,1000 * 10 ** 18);
        govParliament[nodeId].parliament.add(msg.sender);
    }
    
        /*
    @dev /多签竞选投票
    @params Id 节点ID
    @params voteId 当前节点的投票ID
    @params user 投给谁
    @params tickets 投几票
*/
    function voteToParliament(uint id, uint voteId, address user, uint tickets) external override  {
        require(voteId == govParliament[id].voteId);
        require(govParliament[id].votePeriod == true);
        (uint length) = getApplyParliament(id, voteId);
        bool existsUser = false;
        for (uint i = 0; i < length; i++) {
            if (user == parliamentApplyRecords[id][voteId][i].account) {
                existsUser = true;
                parliamentApplyRecords[id][voteId][i].tickets += (tickets);
                break;
            }
        }
        require(existsUser == true);
    }
    
      /*
        @dev 查看议会是否存在某人
        @params 节点id
        @return 是true 否 false
    */
    function hasParliament(uint id, address user) external override view returns (bool){
        return govParliament[id].parliament.contains(user);
    }

    /*
        @dev开启议会投票
        @params
    */
    function _startVoteParliament(uint id) internal{
        uint parliamentLength = govParliament[id].parliament.length();
        for (uint i = 0; i < parliamentLength; i++) {
            address user = govParliament[id].parliament.at(i);
            govParliament[id].parliament.remove(user);
        }
        cityGovernances[id].proposalBlockNumber = block.number;
        govParliament[id].votePeriod = true;
        govParliament[id].voteId = IVoteId(voteIdAddress).incrVoteId();
    }
}

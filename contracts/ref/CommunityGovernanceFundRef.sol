pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "./CoreRef.sol";
import '../interface/gov/ICommunityGovernanceFund.sol';
import '../interface/gov/IBlockNumber.sol';
import './VoteIdRef.sol';
import "../lib/TransferHelper.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
 import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
abstract  contract CommunityGovernanceFundRef  is CoreRef,ICommunityGovernanceFund,VoteIdRef,IBlockNumber{
    using EnumerableSet for EnumerableSet.AddressSet;
      using SafeMath for uint256;
    struct CommunityGovernance {
        uint expireTime;
        address manager;
        uint voteId;
        bool votePeriod;
        bool active;
        uint impeachIndex;
        uint proposalBlockNumber;
    }

    struct parliamentApply {
        address account;
        uint tickets;
    }

    EnumerableSet.AddressSet private parliament;
    CommunityGovernance public override cgInfo;
    mapping(uint => parliamentApply[]) public parliamentApplyRecords;

   mapping(uint =>mapping(address => bool)) public parliamentUp; //弹劾待上位验证
    
     mapping(string =>mapping(address=>uint)) public tokenStorage; //每个选项的代币存储
    mapping(address =>mapping(address => uint)) public managerAndParliamentsReward;

    modifier activated() {
        require(cgInfo.active == true, "GOV MUST ACTIVATED");
        _;
    }



    constructor(address core,address voteIdAddr)  CoreRef(core)  VoteIdRef(voteIdAddr) {}
    /*
    @dev 开启投票
    @params id 某个委员会的id
    */
    function activeToParliaments() public activated() {
        // require(inNode(nodeId, msg.sender), 'not in node');

        require(cgInfo.expireTime < block.timestamp);
        require(cgInfo.votePeriod == false);

        _startVoteParliament();
    }


    function _startVoteParliament() internal{
        uint parliamentLength = parliament.length();
        for (uint i = 0; i < parliamentLength; i++) {
            address user = parliament.at(i);
            parliament.remove(user);
        }
        cgInfo.proposalBlockNumber = block.number;
        cgInfo.votePeriod = true;
        cgInfo.voteId = IVoteId(voteIdAddress).incrVoteId();
    }

    /*
        @dev 获取当前节点的投票所处区块
    */
    function getBlockNumber(uint id) external override view returns(uint) {
         return  cgInfo.proposalBlockNumber;
    }
        /*
       @dev 设置议会成员
       @params nodeid 节点id
       @params voteId 哪次投票产生的
       @params index 成员序号
      */
    function setParliament(uint voteId, uint index) external override  {
        address user = parliamentApplyRecords[voteId][index].account;
//        parliament.add(user);
        parliamentUp[voteId][user] = true;
        cgInfo.impeachIndex++;
    }

    /*
         @dev顺势上位的那个交钱再上
     */
    function parliamentTakeOffice() public {
        require(parliamentUp[cgInfo.voteId][msg.sender],'no access');
        require( IERC20( address(Rbt())).balanceOf(msg.sender) >= 1000 * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(address(Rbt()),msg.sender,address(this),1000 * 10 ** 18);
        parliament.add(msg.sender);
    }



    /*
     @dev 申请竞选
*/
    function applyParliament() external  activated() {
        //        require(inNode(nodeId, msg.sender), 'not in node');
        //todo 判断社区合伙人令牌1枚RBT-Partner或者超级节点令牌1枚RBT-Supnode
        IERC20 rbt = core().rbt();
        TransferHelper.safeTransferFrom(address(rbt),msg.sender,address(this),20000 * 10 ** 18);
        require(cgInfo.votePeriod == true);
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        if (length < 30) {
            require(cgInfo.expireTime < block.timestamp, 'not in time');
        } else {
            require(cgInfo.expireTime < block.timestamp && cgInfo.expireTime + 14 days > block.timestamp, 'not in time');
        }

        _setParliamentApply(cgInfo.voteId,msg.sender,0);
    }
    /*
     @dev 设置申请信息
 */
    function _setParliamentApply( uint voteId,address sender,uint tickets) internal  {
        parliamentApply memory ar = parliamentApply({
        account : msg.sender,
        tickets : 0
        });
        parliamentApplyRecords[voteId].push(ar);
    }

    /*
        @dev /多签竞选投票
        @params nodeId 节点ID
        @params voteId 当前节点的投票ID
        @params user 投给谁
        @params tickets 投几票
    */
    function voteToParliament( uint voteId, address user, uint tickets) external  override activated(){
        require(cgInfo.votePeriod == true);
        require(voteId == cgInfo.voteId);

        uint length = parliamentApplyRecords[voteId].length;
        require(length >=30 && cgInfo.expireTime < block.timestamp,'not in vote time');
        bool existsUser = false;
        for (uint i = 0; i < length; i++) {
            if (user == parliamentApplyRecords[voteId][i].account) {
                existsUser = true;
                parliamentApplyRecords[voteId][i].tickets += (tickets);
                break;
            }
        }
        require(existsUser == true);
    }

        /*
        @dev 结束管理员竞选投票

        */

    function endToParliament() external  activated() {
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        require(length >=15 ,'not enough people');
        require( cgInfo.votePeriod == true);
        _quickSort(parliamentApplyRecords[cgInfo.voteId], 0, length);
        cgInfo.votePeriod = false;
        cgInfo.expireTime = block.timestamp + 30 days;
        //多签30天到期
        cgInfo.manager = parliamentApplyRecords[cgInfo.voteId][0].account;
        for (uint i = 1; i <= 12; i++) {
            parliament.add(parliamentApplyRecords[cgInfo.voteId][i].account);
        }
        if (length > 13) {
            for (uint i = 13; i < length; i++) {
                address user = parliamentApplyRecords[cgInfo.voteId][i].account;
                IERC20 rbt = core().rbt();
                TransferHelper.safeTransferFrom(address(rbt),address(this),msg.sender,20000 * 10 ** 18);
            }
        }
    }



    /*
    @dev 弹劾的赏金发放
    @params nodeId 节点ID
    @params voteId 当前节点的投票ID
 */

    function impeachExtract(address token, uint amount, address receiver) external override onlyVote {
        uint balance =  IERC20(token).balanceOf(address(this));
        require(balance >= amount,'not enough token');
        string[] memory where = new string[](2);
        uint[] memory portion = new uint[](2) ;
        string memory origin = 'PARLIAMENT_STORE';
        if (amount > tokenStorage[origin][token]) {
            where[0] = origin;
            portion[0] = tokenStorage[origin][token];
            uint leftToken = amount - tokenStorage[origin][token];
            if(leftToken > tokenStorage['PUBLIC_STORE'][token]){
                leftToken = tokenStorage['PUBLIC_STORE'][token];
            }
            where[1] = 'PUBLIC_STORE';
            portion[1] = leftToken;
        } else {
            where[0] = origin;
            portion[0] = amount;
        }
        _extract(receiver,portion,where,token);
  
    }
//
//    function _extract(address receiver,uint  amount,address token) internal {
//        IERC20(token).transfer(receiver,amount);
//    }

        function setManagerInfo(address manager) external override  onlyVote {
            cgInfo.manager = manager;
        }

        /*
          @dev 删除某个议会成员
          @params nodeid 节点id
          @params user 议会成员地址
         */

    function removeParliament(address user) external override onlyVote {
            parliament.remove(user);
    }
    function getApplyParliamentVoteId() external  view override   returns (uint){
        return cgInfo.voteId;
    }


    /*
        @dev 查看议会是否存在某人
        @params 节点id
        @return 是true 否 false
    */
    function hasParliament(address user) external override view returns (bool) {
        return  parliament.contains(user);
    }


    //todo  调用core验证来源
    function setUserReward(address user, address token, uint amount, uint operate) public {
        require(operate == 1 || operate == 2,'not access');
        if (operate == 1) {
        managerAndParliamentsReward[user][token] = managerAndParliamentsReward[user][token].add(amount);
        }else if (operate == 2){
        managerAndParliamentsReward[user][token] = managerAndParliamentsReward[user][token].sub(amount);
        }
    }

    /*
        @dev获取用户剩余的奖励
        @params user 账户
        @params token 哪个代币
        @return 数量
    */
    function getUserReward(address user, address token) public view returns (uint) {
        return managerAndParliamentsReward[user][token];
    }




    /*
     @dev设置存款记账
    */
    //todo 验证来源
    function addTokenStorage(string memory store, address token, uint amount) external {
        tokenStorage[store][token] = tokenStorage[store][token].add(amount);
    }

    /*
    @dev 使用资金
    @params receiver 接收人
    @params amount 数量
    @params where 从那种类型里打
    @params token 哪种代币
    */
    function _extract(address receiver,uint[] memory amount,string[] memory where,address token) internal {
        require(amount.length == where.length);
        uint allAmount;
        for(uint i = 0; i<amount.length; i++){
            require(tokenStorage[where[i]][token] >= amount[i]);
            allAmount=allAmount.add(amount[i]);
            tokenStorage[where[i]][token] = tokenStorage[where[i]][token].sub(amount[i]);
        }
        IERC20(token).transfer(receiver,allAmount);
    }


    

    /*
        todo 需要验证来自资金申请合约
    */
    function applyTokenExtract(address receiver, uint[] memory portion, string[] memory where, address token) external override {
        _extract( receiver, portion, where, token);
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

}

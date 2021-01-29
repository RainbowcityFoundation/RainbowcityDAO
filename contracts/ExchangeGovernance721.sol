
pragma solidity ^0.8.0;
import "./interface/token721/IRbtDeposit721.sol";
import "./token721/Governance721.sol";
import "./ref/CoreRef.sol";
import "./interface/token721/IRBTCitynode.sol";

contract ExchangeGovernance721 is CoreRef {
    IRbtDeposit721 deposit;
    IRBTCitynode rbtcitynode;
    string public names;
    address  rbtCitynode;
    uint public value;
    mapping (address=>uint)types;//address->types
    mapping(uint=>uint) public depositAmount; //tokenId->amount
    mapping(uint=>uint) public governance721Amount;//tokenId->amount
    event AddNftToken(uint indexed tokenId,address indexed _address);
    event AddCitynode(address indexed _address,uint indexed tokenId);
    
     //构造函数
    constructor(address core)CoreRef(core){}
    
    function init(address _deposits, address _rbtElf ,address _rbtEnvoy,address _rbtPartner,address _rbtNode)  external {
        deposit=IRbtDeposit721(_deposits);
        types[_rbtElf] = 2000;
        types[_rbtEnvoy] = 10000;
        types[_rbtPartner] = 50000;
        types[_rbtNode] = 100000;
    }
    //增发精灵，大使，合伙人，超级节点令牌  
    function addNftToken( uint tokenId,address _address)external{ 
        address owner=deposit.ownerOf(tokenId);
        //调用者是用户
        require(msg.sender==owner,"Not the token owner");
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        //uint startTime=deposit.startTime(tokenId);
        uint expireTime=deposit.expire(tokenId);
        uint month=(expireTime-blockTime)/2592000;
        if(depositAmount[tokenId] == 0){
            depositAmount[tokenId] = deposit.amount(tokenId);
        }
        require(depositAmount[tokenId]>=types[_address]&&month>=12,"not sufficient funds ");
        Governance721(_address).mint(expireTime,owner);
        depositAmount[tokenId] = depositAmount[tokenId]-types[_address];
        if(depositAmount[tokenId] == 0){
            depositAmount[tokenId] = 1;
        } 
        emit AddNftToken(tokenId, _address);
    }

    //增发城市节点令牌 
    function addCitynode(address _address,uint tokenId)external{
        address owner=Governance721(_address).ownerOf(tokenId);
        uint amount=Governance721(_address).usableBalanceOf(owner);
        names=Governance721(_address).name();
        //当前区块的时间，在unit32范围内
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        uint expireTime=blockTime+2592000*3;
        //生成citynodede的的额度
        if(governance721Amount[tokenId] == 0){
             governance721Amount[tokenId]=Governance721(_address).usableBalanceOf(owner);
        }

        if(keccak256(abi.encodePacked(names)) == keccak256(abi.encodePacked("RbtEnvoy")) && amount>=1){
            
            rbtcitynode.mint(expireTime, owner);
            governance721Amount[tokenId]=governance721Amount[tokenId]-1;
        }
        else if(keccak256(abi.encodePacked(names)) == keccak256(abi.encodePacked("RbtPartner")) && amount>=1){
            
            for (uint i = 1; i <=3; i++){
                rbtcitynode.mint(expireTime, owner);
            }
            governance721Amount[tokenId]=governance721Amount[tokenId]-1;
        }
        else if(keccak256(abi.encodePacked(names)) == keccak256(abi.encodePacked("RbtNode")) && amount>=1){
            
            for (uint i = 1; i <=5; i++){
                rbtcitynode.mint(expireTime, owner);
            }
            governance721Amount[tokenId]=governance721Amount[tokenId]-1;
        }

        
        if(governance721Amount[tokenId] == 0){
            governance721Amount[tokenId] = 1;
        } 

        emit AddCitynode(_address, tokenId);  
    }
}


pragma solidity ^0.8.0;
import "../interface/token721/IRbtDeposit721.sol";
import "../lib/TokenSet.sol";
import "../interface/token721/IERC721Receiver.sol";
import "../ref/CoreRef.sol";
import "../interface/token721/IRBTCitynode.sol";

//Governance token
contract RBTCitynode is CoreRef,IRBTCitynode {
    using Set for Set.TokenIdSet;
    string public name;
    address private elf;
    address private envoy;
    address private partner;
    address private node;
    address exchangeGovernance721;
    //Total number of tokens
    uint public Lengths;
    //Number of expired user tokens
    uint16 nums;
    //Number of expired user tokens
    uint []  unfixedArr;
    RBTCitynode[] private list ;
    mapping(address=>Set.TokenIdSet) userToken ;
    mapping (uint256 => address) private _tokenApprovals;// tokenId----Authorized address
    //Mapping from owner to operator when sublicensing
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    struct RBTCitynode {
        address owner;
        uint tokenId;
        uint startTime;
        uint expireTime;
    }
    
    constructor(address core,address _exchangeGovernance721, string memory  _name  )CoreRef(core){
        name = _name;
        exchangeGovernance721=_exchangeGovernance721;
    }
    
    /*
    * To raise the token
    */
    function mint(uint times,address from) onlyExchangeGovernance721 external override  returns(uint) {
        //Time of the current block
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        uint tokenId=list.length+1;
        RBTCitynode memory record = RBTCitynode({
            owner : from,
            tokenId : tokenId,
            startTime:blockTime,
            expireTime:times
        });
        list.push(record);
        Lengths=list.length;
        userToken[from].add(tokenId);
        return  tokenId;
    }

    //Find the owner address based on tokenID
    function ownerOf(uint256 _tokenId) public view override returns (address owner){
        owner=list[_tokenId-1].owner;
    }

    //View all expired tokens
    function getAllInvalidToken() public  returns (uint[] memory ) {
        //Time of the current block
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        for(uint i=0; i<Lengths;i++) {
             RBTCitynode memory rbtCitynode =list[i];
             if(rbtCitynode.expireTime<blockTime){
                unfixedArr.push(list[i].tokenId);
             }
          }
        return(unfixedArr);
    }

    //View an expired token  
    function userUsableTonken(address user) public  returns (uint16 num){
        //Time of the current block
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        uint lengths=userToken[user].length();
        for(uint i=0;i<lengths;i++){
            if(list[userToken[user].at(i)-1].expireTime<blockTime){
                nums++;
            }
        }
        num=nums;
    }

    //View the total number of tokens available
    function usableTotalSupply() public view override returns (uint256 usableTotalSupply){
        usableTotalSupply=Lengths-unfixedArr.length;
    }

    //Total number of tokens issued
    function totalSupply() public view override returns (uint256 totalSupply){
        totalSupply=Lengths;
    }
    
    //Total number of tokens available to the user
     function usableBalanceOf(address _owner) public view override returns (uint usableBalanceOf){
        usableBalanceOf=userToken[_owner].length()-nums;
    }

    //Total number of tokens for the user
    function balanceOf(address _owner) public view override returns (uint balance){
        balance=userToken[_owner].length();
    }
    
    //Query the token validity period
    function expire(uint256 tokenId) public view override returns(uint){
        return  list[tokenId-1].expireTime;
    }
    
    //Whether tokenId exists 
    function _exists(uint256 tokenId) public view override returns (bool) {
        return list[tokenId].owner != address(0);
    }
    
    //Query any token in the tokenID list of a user  
     function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return userToken[owner].at(index);
    }
    
    //View token information
    function tokenMetadata(uint _tokenId) public view  returns (RBTCitynode memory ) {
        return list[_tokenId-1];
    }
    
    //The token transfer
    function transfer(address _from, address _to, uint256 _tokenId) public   {
        require(ownerOf(_tokenId) == _from&&list[_tokenId].expireTime>block.timestamp, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        userToken[_from].remove(_tokenId);
        userToken[_to].add(_tokenId);
        list[_tokenId-1].owner=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    //Grant address _to control of _tokenId    
    function approve(address _to, uint256 _tokenId)public override {
        require(msg.sender == list[_tokenId].owner&&list[_tokenId].expireTime>block.timestamp);
        require(msg.sender != _to);//Empowerment is not about you
        _tokenApprovals[_tokenId] = _to;
        emit Approval(list[_tokenId].owner, _to, _tokenId);
    }
    
    //Approved address
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    //Query authorization
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    
    //Grant the address _operator control over all NFTs, and upon success trigger the ApprovalForAll event .
    function setApprovalForAll(address operator, bool approved) public override virtual  {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    //Used to query authorization
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    //Transfer NFT ownership
     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override virtual   {
        transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    //Transfer NFT ownership
    function safeTransferFrom(address from, address to, uint256 tokenId) public override virtual  {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    //Internal function, called at the target address, if the target address is not the protocol, the call is not executed.  
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private   returns (bool){
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } 
         return true;
    }

    //Is it a contract address
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

      //Decorator to check whether the caller is a bank ExchangeGovernance721
    modifier onlyExchangeGovernance721 {
        require(msg.sender==exchangeGovernance721, "is not ExchangeGovernance721");
        _;
    }

}
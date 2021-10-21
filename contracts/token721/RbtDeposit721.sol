pragma solidity ^0.8.0;
import "../interface/token721/IRbtDeposit721.sol";
import "../lib/TokenSet.sol";
import "../interface/token721/IERC721Receiver.sol";
import "../interface/bank/IRbBank.sol";
import "../ref/CoreRef.sol";

    //Deposit the token
    contract RbtDeposit721 is CoreRef,IRbtDeposit721 {
        using Set for Set.TokenIdSet;
        struct Deposit{
            address owner;
            uint tokenId;
            uint startTime;
            uint expireTime;
            uint amount;
    }
    
     //Constructo
    constructor(address core)CoreRef(core){}
    
    function init(address _bank) external {
        bank =_bank;
    }

    //bank address
    address bank;
    //Total number of tokens
    uint Lengths;
    Deposit[] private list ;
    mapping(address=>Set.TokenIdSet) userToken ;
    mapping (uint256 => address) private _tokenApprovals;// tokenId----Authorized address
    //Mapping from owner to operator when sublicensing
    mapping (address => mapping (address => bool)) private _operatorApprovals;
   
    /*
    * To issue additional tokens, only the bank can issue additional tokens (_isBank) to obtain certificates .
    */
    function mint(address to,  uint amounts, uint month) onlyBank external override returns(uint) {
        //Time of the current block
        uint32 blockTime = uint32(block.timestamp % 2 ** 32);
        //Issue a new token, the number of orders for that address increases by 1
        uint256 tokenId = list.length+1;
        uint expireTime=blockTime +(month*2592000);
        Deposit memory record = Deposit({
            owner : to,
            tokenId : tokenId,
            startTime:blockTime,
            expireTime:expireTime,
            amount: amounts
        });
        list.push(record);
        Lengths=list.length;
        userToken[to].add(tokenId);
        return  tokenId;
    }

    //Destruction of the token
    function burn(uint256 tokenId) onlyBank external override  virtual {
        address owner = ownerOf(tokenId);
        userToken[owner].remove(tokenId);
        delete list[tokenId-1];
        Lengths=list.length-1;
        emit Transfer(owner, address(0), tokenId);
    }
    
    //Find the owner address based on tokenID
    function ownerOf(uint256 _tokenId) public view override returns (address owner){
        owner=list[_tokenId-1].owner;
    }
    //Total number of tokens issued
    function totalSupply() public view returns (uint256 totalSupply){
        totalSupply=Lengths;
    }

    //The number of tokens for the user
    function balanceOf(address _owner) public view override returns (uint balance){
        balance=userToken[_owner].length();
    }

    //Query the number of tokens pledged
    function amount(uint256 tokenId) public view override returns(uint){
        return  list[tokenId-1].amount;
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
    function tokenMetadata(uint _tokenId) public view  returns (Deposit memory ) {
        return list[_tokenId-1];
    }

    //The token transfer
    function transfer(address _from, address _to, uint256 _tokenId) public  {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        userToken[_from].remove(_tokenId);
        userToken[_to].add(_tokenId);
        list[_tokenId-1].owner=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    //Grant address _to control of _tokenId  
    function approve(address _to, uint256 _tokenId)public override {
        require(msg.sender == list[_tokenId].owner);
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
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
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
    
    //Decorator to check whether the caller is a bank
    modifier onlyBank {
        require(msg.sender==bank, "is not bank");
        _;
    }
}
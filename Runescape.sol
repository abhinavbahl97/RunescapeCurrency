pragma solidity  ^0.5.1;


    	interface ERC721  {
      	 
     	 
  	//  	function getBalance(address _owner) external view returns (uint256);
      	//  function ownerOf(uint256 _tokenId) external view returns (address);
          	function TransferToken(address _from, address _to, uint256 _tokenId) external payable;

    	}

    	// interface ERC721TokenReceiver {
    	// 	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
    	//  }
    	 
     	contract Runescape is ERC721{
        	 
        	address private OwnerAddress; //address of the owner
        	uint private StartingPrice; 
        	string private ItemGrade;   //Item Attributes
        	uint private TokenID;       
        	mapping (uint => address) TokenOwner; //Keeps track of Token owner
       	 
        	uint private MaxDuration = 24 hours;
        	uint private MinDuration = 1 hours;
        	uint private AuctionEndTime;    //Time left for auction to end
        	bool private AuctionDidEnd;     // Boolean to check if auction ended
       	 
        	address private BidderAddress;  //Address of current bidder
        	address private HighestBidder;  // Address of highest bidder
        	uint private HighestBid;        // Value of Highest Bid
        	bool private sell;              //Option to allow user to sell their 
        	                                //item to the first bidder

        	mapping (address => bool) BlockedUsers;

            //Constructor to create the token
        	constructor (address _Owner, uint _StartingPrice,
         	uint _Duration, bool _sell,
         	uint _TokenID, string memory _ItemGrade) public payable {
          	OwnerAddress = _Owner;
          	StartingPrice = _StartingPrice;
          	TokenID = _TokenID;
          	TokenOwner[_TokenID] = _Owner;
          	AuctionDidEnd = false;
          	sell = _sell;
          	ItemGrade = _ItemGrade;

            	if (_Duration >= MinDuration && _Duration <= MaxDuration) {
                	AuctionEndTime = block.timestamp + _Duration;
            	} else if (_Duration < MinDuration) {
                	AuctionEndTime = block.timestamp + MinDuration;
            	} else {
                	AuctionEndTime = block.timestamp + MaxDuration;
            	}
         	}
            	//Getter for AuctionEndTime
        	function getEndTime() public view returns(uint) {
                	return AuctionEndTime;
            	}
       	 
            	// Getter for the StartingPrice
        	function getStartingPrice() public view returns(uint) {
                	return StartingPrice;
            	}
        	// Getter for HighestBid
        	function getHighestBid() public view returns(uint) {
                    	if (sell == true) {
                        	revert();
                    	}
                    	return HighestBid;
            	}   
       	 
        	//Updates the Bid if it meets criteria
        	function UpdateBid(address _Bidder, uint _Bid) external {
            	//Did the auction already end?
         	checkIfAuctionEnded();
         	//Is the bidder a blocked user?
        	if(BlockedUsers[_Bidder]){
            	revert();
        	}
        	//Is the bidder the owner of the bid (cannot bid)
        	if(_Bidder == OwnerAddress){
        	revert();
        	}
       	 
         	require(BlockedUsers[_Bidder] == false);
        	 
         	// did the auction end or was the item already sold
        	if(AuctionDidEnd == true || sell == true) {
            	revert();
        	}
        	// Is the new bid higher than the current bid & starting price
        	if (_Bid > HighestBid && _Bid >= StartingPrice) {
                    	HighestBidder = _Bidder;
                    	HighestBid = _Bid;
            	}
            	//If they don't have the funds, or bid lower than the starting price, they are blocked. Don't spam the system
        	// else if(getBalance() < _Bid || _Bid < StartingPrice)
        	// 	{
        	// 	AddToBlockList(_Bidder);
        	// 	}
        	}
       	 
        	//Function for owner to update time if desired
        	function UpdateTime(uint NewTime) OwnerFunc external {
        	if (AuctionEndTime + NewTime < MaxDuration) {
            	AuctionEndTime = AuctionEndTime + NewTime;
        	}
        	else {
        	AuctionEndTime = MaxDuration;
        	}
    	}

        	//Checks if auction ended, if so then transfer the item over
        	function checkIfAuctionEnded() private {
            	if (block.timestamp >= AuctionEndTime){
                	AuctionDidEnd= true;
                	TransferToken(OwnerAddress, HighestBidder, TokenID);
           	}
        	}
       	 
    	//Get balance of this contract? Not quite sure
  	function getBalance() public view returns (uint256) {
    	return address(this).balance;
  	}
  	    //Allows seller to instantly sell their item to the first bidder
  	function InstantBuy(address _BidderAddress) external {
        if (AuctionDidEnd) {
            revert();
        }
        else if (sell) {
            AuctionDidEnd = true;
            BidderAddress = _BidderAddress;
            TransferToken(OwnerAddress, _BidderAddress, TokenID);
        }
    }
    
	//transfer the item to the highest bidder
	function TransferToken(address _from, address _to, uint256 _tokenId) public payable {
    	require(AuctionDidEnd == true);
    	if (sell == false && _to != HighestBidder) {
        	AddToBlockList(_to);
    	}
    	if (sell == true && _to != BidderAddress) {
        	AddToBlockList(_to);
    	}
    	if (TokenOwner[_tokenId] != _from) {
        	AddToBlockList(_from);
    	}
    	else {
    	TokenOwner[_tokenId] = _to;
    	}
	}
    
	//add users to block list
	function AddToBlockList(address BannedUser) private {
    	BlockedUsers[BannedUser] = true;
	}
	//owner function to end bid now and confirm if transfer should happen or not
	function EndBidding(bool confirmtransfer) OwnerFunc external {
    	AuctionDidEnd = true;
    	if (sell == false && confirmtransfer == true) {
        	TransferToken(OwnerAddress, HighestBidder, TokenID);
    	}
	}

	//This modifier requires the owner to be the one to call the method
	modifier OwnerFunc {
    	require(OwnerAddress == msg.sender);
    	_;
	}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./NFT.sol";

contract Auction {
    
    using SafeMath for uint256; 
    uint256 public platformFee;
    
    struct orderDetails {
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 totalPrice;
        uint256 time;
    }
    
    mapping(address=>orderDetails[]) public orderLogs;
 
    address public contractOwner ;
    
    struct forBids{
        uint256 bidPrice;
        address bidder;
        uint256 tokenid;
    }

    forBids[] bidsArray;

    mapping(uint256 => forBids) public bidsmapping;


    struct onSaleItem {
        uint256 tokenId;
        address owner;
        bool sold;
        bool onSale;
        uint256 timeOnsale;
        uint256 price;
    }
    
    mapping(uint256=>onSaleItem) public saleItems;
     
    NFT public nft;
     
    struct onBidItem{
        uint256 tokenId;
        address  owner;
        bool sold;
        bool onBid;
        uint256 timeOnBid;
        uint256  timeTillBidComplete;
    }
    
    mapping( uint256 => onBidItem) public bidItems;
     
    
    constructor(address nftCreation, uint256 _platformFee) {
        nft = NFT(nftCreation);
        contractOwner = msg.sender;
        platformFee = _platformFee;
    }
        
    event PutTokenOnBid(uint256 tokenId,uint256 bidCompleteTime,address tokenOwner);
    event MakeBid(uint256 _bidprice,uint256 _tokenId,address bidder);
    event OnBidComplete(uint256 tokenId,address winner,uint256 _bidprice,address tokenOwner,orderDetails newOrder);
    event RemoveTokenFromBid(uint256 tokenId,address tokenOwner,bool isOnBid);
    event ChangeBidTokenStatus(uint256 tokenId,bool isSold);
        
    modifier checkTokenOwner(uint256 tokenId){
      require(nft.balanceOf(msg.sender)!=0,'You do not own the token');
        _;  
    }
    
    modifier onlyOwner(){
        require(msg.sender == contractOwner,"You are not permitted to call this function");
        _;
    }
     
    modifier tokenNotSoldAlready(uint256 tokenId){
        require(!bidItems[tokenId].sold,"Token is already sold!");
        _;
    }
    
    function getBidsArray()public view returns(forBids[] memory){
        return bidsArray;
    }
    
     // Get the all order logs for perticualr buyer.
    function viewOrderLogs()external view returns(orderDetails[] memory ){
        uint length=orderLogs[msg.sender].length;
         orderDetails[] memory records = new orderDetails[](length);
        for (uint i=0; i<length; i++) {
            orderDetails storage orderDetail = orderLogs[msg.sender][i];
            records[i]=orderDetail;
        }
        return records;
    }
    
    function removeTokenFromBid(uint256 tokenId)external returns(bool){
        
        require(nft.balanceOf(msg.sender)!=0 ,"You donot own the token");
        bidItems[tokenId].onBid=false;
        emit RemoveTokenFromBid(tokenId,msg.sender,false);
        //from node side=>nft.setApprovalForAll(address(this),false);
        return true;
    }
    
    function changeBidTokenStatus(uint256 tokenId,bool status)internal tokenNotSoldAlready(tokenId) onlyOwner() returns(bool){
      bidItems[tokenId].sold=status;
       emit ChangeBidTokenStatus(tokenId,status);
        return true;
    }
    
    function putTokenOnBid(uint256 tokenId,uint256 bidCompleteTime)external payable returns(bool){
     //node side => nft.setApprovalForAll(address (this),true);
        onBidItem memory newBidItem=onBidItem({
            tokenId:tokenId, 
            owner:msg.sender,
            sold:false,
            onBid:true,
            timeOnBid:block.timestamp,
            timeTillBidComplete:bidCompleteTime
           
        });
        bidItems[tokenId]=newBidItem;
        emit PutTokenOnBid(tokenId,bidCompleteTime,msg.sender);
        return true;
    }
    
    function placeBid(uint256 _tokenId) public payable {
        
        require(bidItems[_tokenId].owner!= msg.sender, "OWNER_OF_TOKEN_CANNOT_PLACE_A_BID");
        require(bidItems[_tokenId].timeTillBidComplete < block.timestamp, "BIDDING_PERIOD_COMPLETED");
        require(bidItems[_tokenId].timeOnBid != 0, "TOKEN_IS_NOT_BUYABLE");
        require(!bidItems[_tokenId].sold, "TOKEN_ALREADY_SOLD");
        require(bidItems[_tokenId].onBid == true, "TOKEN_IS_NOT_ON_BID");
        
        // Check if someone bidded previously
        uint256 prevBidPrice = bidsmapping[_tokenId].bidPrice;
        
        require(prevBidPrice < msg.value, "YOUR_BID_VALUE_IS_LESS_THAN_CURRENT_BID");
        
        // Refund Last Bidder
        address lastBidder = bidsmapping[_tokenId].bidder;
        payable(lastBidder).transfer(prevBidPrice);
        
        // Update Bid
        bidsmapping[_tokenId].bidPrice = msg.value;
        bidsmapping[_tokenId].bidder = msg.sender;
        bidsmapping[_tokenId].tokenid = _tokenId;
        
        
        forBids memory newBid=forBids({
            bidder : msg.sender,
            bidPrice: msg.value,
            tokenid:_tokenId
        });
        
        bidsArray.push(newBid);
        emit MakeBid(msg.value, _tokenId, msg.sender);
    }
   
    function onBidComplete(uint256 tokenId) external onlyOwner() tokenNotSoldAlready(tokenId) payable returns(orderDetails memory){
        
        require((block.timestamp - bidItems[tokenId].timeTillBidComplete)>=0,"Bidding time is still running");
        require(bidItems[tokenId].timeOnBid!=0,"Token is not buyable!");
        require(!bidItems[tokenId].sold,"Token is already sold!");
        require(bidItems[tokenId].onBid == true,"Token is not on Bid!");
        require(nft.isApprovedForAll(bidItems[tokenId].owner,address(this)),'Token is not approved to tranfer!');

        orderDetails memory newOrder = orderDetails({
            tokenId: tokenId,
            buyer: bidsmapping[tokenId].bidder,
            seller: bidItems[tokenId].owner,
            totalPrice:bidsmapping[tokenId].bidPrice,
            time:block.timestamp
        });
        
        orderLogs[bidsmapping[tokenId].bidder].push(newOrder);
        changeBidTokenStatus(tokenId,true);  
        
        uint256 bidPrice = bidsmapping[tokenId].bidPrice;
        uint256 amount = bidPrice.sub(bidPrice.mul(platformFee).div(100));
        payable(contractOwner).transfer(bidPrice.mul(platformFee).div(100));
        
        payable(bidItems[tokenId].owner).transfer(amount);
        
        nft.safeTransferFrom(bidItems[tokenId].owner,bidsmapping[tokenId].bidder,tokenId);
        emit OnBidComplete(tokenId,bidsmapping[tokenId].bidder,bidsmapping[tokenId].bidPrice, bidItems[tokenId].owner,newOrder);
        return newOrder;
    }
    
}

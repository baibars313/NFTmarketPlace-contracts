// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./safeMath.sol";
pragma solidity ^0.8.20;





contract Marketplace is Ownable {
    using SafeMath for uint256;

    struct SaleItem {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address owner;
        bool isERC721;
        uint amount;
    }

    struct AuctionItem {
        address nftContract;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        address owner;
        bool isERC721;
        bool isActive;
        uint amount;
    }

    uint256 public marketplaceFee; // Fee in percentage (e.g., 5 for 5%)

    uint256 public itemIdCounter;
    uint256 public auctionItemIdCounter;

    mapping(uint256 => SaleItem) public saleItems;
    mapping(uint256 => AuctionItem) public auctionItems;
    mapping(uint256 => mapping(address => uint256)) public bids;

    event ItemListed(uint256 tokenId, uint256 price, bool isERC721);
    event ItemRemoved(uint256 tokenId);
    event ItemPriceChanged(uint256 tokenId, uint256 newPrice);
    event ItemSold(uint256 tokenId, address buyer, uint256 price);
    event AuctionItemAdded(uint256 tokenId, uint256 startingPrice, uint256 endTime, bool isERC721);
    event AuctionItemSold(uint256 tokenId, address buyer, uint256 price);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event BidWithdrawn(uint256 tokenId, address bidder, uint256 amount);
    event BidAccepted(uint256 tokenId, address bidder, uint256 amount);

    modifier onlyItemOwner(uint256 tokenId) {
        require(msg.sender == saleItems[tokenId].owner || msg.sender == auctionItems[tokenId].owner, "Not the item owner");
        _;
    }

    modifier onlyAuctionItemOwner(uint256 tokenId) {
        require(msg.sender == auctionItems[tokenId].owner, "Not the auction item owner");
        _;
    }

    modifier onlyHighestBidder(uint256 tokenId) {
        require(msg.sender == auctionItems[tokenId].highestBidder, "Not the highest bidder");
        _;
    }

    modifier auctionActive(uint256 tokenId) {
        require(auctionItems[tokenId].isActive, "Auction is not active");
        _;
    }

    modifier onlyNFTOwner(address nftContract, uint256 tokenId,uint amount) {
        if (_checkIsERC721(nftContract)) {
            require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        } else {
            require(IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= amount, "Not enough ERC1155 tokens owned");
        }
        _;
    }

    function isEOA(address _address) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size == 0;
    }


     modifier onlyEOA() {
        require(isEOA(msg.sender), "Only EOAs are allowed");
        _;
    }

    constructor(uint256 _marketplaceFee) Ownable(msg.sender) {
        require(_marketplaceFee <= 100, "Fee should be in percentage");
        marketplaceFee = _marketplaceFee;
    }

    function listForSale(address nftContract, uint256 tokenId, uint256 price,uint _amount) external onlyNFTOwner(nftContract, tokenId,_amount) {
        require(price > 0, "Price must be greater than zero");
        bool isERC721 = _checkIsERC721(nftContract);

        uint256 itemId = _getNextItemId();
        saleItems[itemId] = SaleItem({
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            owner: msg.sender,
            isERC721: isERC721,
            amount: _amount
        });

        emit ItemListed(itemId, price, isERC721);
    }

     function sent(address payable _to, uint256 _amount) internal returns (bool){
        (bool _sent,) = _to.call{value: _amount}("");
        return  _sent;
    }

    function removeFromSale(uint256 itemId) external onlyItemOwner(itemId) {
        delete saleItems[itemId];
        emit ItemRemoved(itemId);
    }

    function changeSalePrice(uint256 itemId, uint256 newPrice) external onlyItemOwner(itemId) {
        require(newPrice > 0, "Price must be greater than zero");
        saleItems[itemId].price = newPrice;
        emit ItemPriceChanged(itemId, newPrice);
    }

    function purchase(uint256 itemId) external payable {
        SaleItem storage saleItem = saleItems[itemId];
        require(saleItem.owner != address(0), "Item not listed for sale");
        require(msg.value >= saleItem.price, "Insufficient funds");
        address admin = owner();
        uint256 adminFee = (msg.value.mul(marketplaceFee)).div(100);
        uint256 sellerProceeds = msg.value.sub(adminFee);
        bool _sentSeller=sent(payable(saleItem.owner) , sellerProceeds);
        bool _sentOwner=sent(payable(admin) , adminFee);
        require(_sentSeller, 'unable to pay price ');
        require(_sentOwner, 'unable to pay owner fee');
        if (saleItem.isERC721) {
            IERC721(saleItem.nftContract).transferFrom(saleItem.owner, msg.sender, saleItem.tokenId);
        } else {
            IERC1155(saleItem.nftContract).safeTransferFrom(saleItem.owner, msg.sender, saleItem.tokenId, 1, "");
        }
        delete saleItems[itemId];
        emit ItemSold(itemId, msg.sender, msg.value);
    }

    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice, uint256 duration, uint _amouont) external onlyNFTOwner(nftContract, tokenId,_amouont) {
        bool isERC721 = _checkIsERC721(nftContract);
        uint256 endTime = block.timestamp + duration;

        uint256 auctionItemId = _getNextAuctionItemId();
        auctionItems[auctionItemId] = AuctionItem({
            nftContract: nftContract,
            tokenId: tokenId,
            startingPrice: startingPrice,
            highestBid: startingPrice,
            highestBidder: address(this),
            endTime: endTime,
            owner: msg.sender,
            isERC721: isERC721,
            isActive: true,
            amount:_amouont
        });

        emit AuctionItemAdded(auctionItemId, startingPrice, endTime, isERC721);
    }

    function placeBid(uint256 auctionItemId) external payable auctionActive(auctionItemId) onlyEOA {
        AuctionItem storage auctionItem = auctionItems[auctionItemId];
        require(msg.value > auctionItem.highestBid, "Bid must be greater than the current highest bid");
        require(block.timestamp < auctionItem.endTime, "Auction has ended");
        bids[auctionItemId][auctionItem.highestBidder] = 0;
        auctionItem.highestBid = msg.value;
        auctionItem.highestBidder = msg.sender;
        bids[auctionItemId][msg.sender] = msg.value;
        payable(auctionItem.highestBidder).transfer(bids[auctionItemId][auctionItem.highestBidder]);
        emit BidPlaced(auctionItemId, msg.sender, msg.value);
    }

    function acceptBid(uint256 auctionItemId) external onlyAuctionItemOwner(auctionItemId) auctionActive(auctionItemId) {
        AuctionItem storage auctionItem = auctionItems[auctionItemId];
        address admin = owner();
        uint256 adminFee = (auctionItem.highestBid * marketplaceFee) / 100;
        uint256 sellerProceeds = auctionItem.highestBid - adminFee;
        if (auctionItem.isERC721) {
            IERC721(auctionItem.nftContract).transferFrom(auctionItem.owner, auctionItem.highestBidder, auctionItem.tokenId);
        } else {
            IERC1155(auctionItem.nftContract).safeTransferFrom(auctionItem.owner, auctionItem.highestBidder, auctionItem.tokenId, 1, "");
        }
        delete auctionItems[auctionItemId];
        payable(admin).transfer(adminFee);
        payable(auctionItem.owner).transfer(sellerProceeds);
        emit AuctionItemSold(auctionItemId, auctionItem.highestBidder, auctionItem.highestBid);
        
    }

    function withdrawBid(uint256 auctionItemId) external auctionActive(auctionItemId) {
        uint256 bidAmount = bids[auctionItemId][msg.sender];
        require(bidAmount > 0, "No active bid");
        bids[auctionItemId][msg.sender] = 0;
        payable(msg.sender).transfer(bidAmount);
        emit BidPlaced(auctionItemId, msg.sender, 0);
    }

    function getBidAmount(uint256 auctionItemId) external view returns (uint256) {
        return bids[auctionItemId][msg.sender];
    }

    function _getNextItemId() internal returns (uint256) {
        itemIdCounter++;
        return itemIdCounter;
    }

    function _getNextAuctionItemId() internal returns (uint256) {
        auctionItemIdCounter++;
        return auctionItemIdCounter;
    }

    function _checkIsERC721(address nftContract) internal view returns (bool) {
        (bool success, ) = nftContract.staticcall(abi.encodeWithSelector(IERC721.ownerOf.selector, 1));
        return success;
    }
}
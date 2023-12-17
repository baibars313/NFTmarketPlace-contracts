// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./safeMath.sol";

contract Marketplace is Ownable {
    using SafeMath for uint256;
    

    struct SaleItem {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address owner;
        bool isERC721;
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
    }

    struct UnlistedNFT {
        address nftContract;
        uint256 tokenId;
        bool isActive;
    }

    struct BidInfo {
        uint256 amount;
        bool withdrawn;
    }

    uint256 public marketplaceFee; // Fee in percentage (e.g., 5 for 5%)

    uint256 public itemIdCounter;
    uint256 public auctionItemIdCounter;
    uint256 public unlistbIdIdCounter;
    uint256 public unlistedBidIdCounter;

    mapping(uint256 => SaleItem) public saleItems;
    mapping(uint256 => AuctionItem) public auctionItems;
    mapping(uint256 => mapping(address => BidInfo)) public bids;
    mapping(uint256 => UnlistedNFT) public unlistedNFTs;
    mapping(uint256 => mapping(address => BidInfo)) public unlistedBids;
    mapping(uint256 => mapping(address => BidInfo)) public unlistedItemBids;

    event ItemListed(uint256 tokenId, uint256 price, bool isERC721);
    event ItemRemoved(uint256 tokenId);
    event ItemPriceChanged(uint256 tokenId, uint256 newPrice);
    event ItemSold(uint256 tokenId, address buyer, uint256 price);
    event AuctionItemAdded(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endTime,
        bool isERC721
    );

    event AuctionItemSold(uint256 tokenId, address buyer, uint256 price);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event BidWithdrawn(uint256 tokenId, address bidder, uint256 amount);
    event BidAccepted(uint256 tokenId, address bidder, uint256 amount);

    modifier onlyItemOwner(uint256 tokenId) {
        require(
            msg.sender == saleItems[tokenId].owner ||
                msg.sender == auctionItems[tokenId].owner,
            "Not the item owner"
        );
        _;
    }

    modifier onlyAuctionItemOwner(uint256 tokenId) {
        require(
            msg.sender == auctionItems[tokenId].owner,
            "Not the auction item owner"
        );
        _;
    }

    modifier onlyHighestBidder(uint256 tokenId) {
        require(
            msg.sender == auctionItems[tokenId].highestBidder,
            "Not the highest bidder"
        );
        _;
    }

    modifier auctionActive(uint256 tokenId) {
        require(auctionItems[tokenId].isActive, "Auction is not active");
        _;
    }

    modifier onlyNFTOwner(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) {
        if (_checkIsERC721(nftContract)) {
            require(
                IERC721(nftContract).ownerOf(tokenId) == msg.sender,
                "Not the NFT owner"
            );
        } else {
            require(
                IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= amount,
                "Not enough ERC1155 tokens owned"
            );
        }
        _;
    }

    constructor(uint256 _marketplaceFee) Ownable(msg.sender) {
        require(_marketplaceFee <= 100, "Fee should be in percentage");
        marketplaceFee = _marketplaceFee;
    }

    // Internal function to generate the next item ID
    function _getNextItemId() internal returns (uint256) {
        itemIdCounter++;
        return itemIdCounter;
    }

    // Internal function to generate the next auction item ID
    function _getNextAuctionItemId() internal returns (uint256) {
        auctionItemIdCounter++;
        return auctionItemIdCounter;
    }

    // Internal function to generate the next unlisted item ID
    function _getNextUnlistbIdId() internal returns (uint256) {
        unlistbIdIdCounter++;
        return unlistbIdIdCounter;
    }

    // Internal function to generate the next unlisted bid ID
    function _getNextUnlistedBidId() internal returns (uint256) {
        unlistedBidIdCounter++;
        return unlistedBidIdCounter;
    }

    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function listForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant onlyNFTOwner(nftContract, tokenId, 1) {
        require(price > 0, "Price must be greater than zero");
        bool isERC721 = _checkIsERC721(nftContract);

        uint256 itemId = _getNextItemId();
        saleItems[itemId] = SaleItem({
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            owner: msg.sender,
            isERC721: isERC721
        });

        emit ItemListed(itemId, price, isERC721);
    }

    function removeFromSale(uint256 itemId)
        external
        onlyItemOwner(itemId)
        nonReentrant
    {
        delete saleItems[itemId];
        emit ItemRemoved(itemId);
    }

    function changeSalePrice(uint256 itemId, uint256 newPrice)
        external
        onlyItemOwner(itemId)
        nonReentrant
    {
        require(newPrice > 0, "Price must be greater than zero");
        saleItems[itemId].price = newPrice;
        emit ItemPriceChanged(itemId, newPrice);
    }

    function purchase(uint256 itemId) external payable nonReentrant {
        SaleItem storage saleItem = saleItems[itemId];
        require(saleItem.owner != address(0), "Item not listed for sale");
        require(msg.value >= saleItem.price, "Insufficient funds");

        address admin = owner();
        uint256 adminFee = (msg.value.mul(marketplaceFee)).div(100);
        uint256 sellerProceeds = msg.value.sub(adminFee);

        // Transfer funds using SafeMath
        payable(admin).transfer(adminFee);
        payable(saleItem.owner).transfer(sellerProceeds);

        // Transfer NFT
        if (saleItem.isERC721) {
            IERC721(saleItem.nftContract).transferFrom(
                saleItem.owner,
                msg.sender,
                saleItem.tokenId
            );
        } else {
            IERC1155(saleItem.nftContract).safeTransferFrom(
                saleItem.owner,
                msg.sender,
                saleItem.tokenId,
                1,
                ""
            );
        }

        // Remove item from sale
        delete saleItems[itemId];

        emit ItemSold(itemId, msg.sender, msg.value);
    }

    // Auction Functions
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) external  onlyNFTOwner(nftContract, tokenId, 1) {
        bool isERC721 = _checkIsERC721(nftContract);
        uint256 endTime = block.timestamp + duration;

        uint256 auctionItemId = _getNextAuctionItemId();
        auctionItems[auctionItemId] = AuctionItem({
            nftContract: nftContract,
            tokenId: tokenId,
            startingPrice: startingPrice,
            highestBid: startingPrice,
            highestBidder: msg.sender,
            endTime: endTime,
            owner: msg.sender,
            isERC721: isERC721,
            isActive: true
        });

        emit AuctionItemAdded(auctionItemId, startingPrice, endTime, isERC721);
    }

    function placeBid(uint256 auctionItemId)
        external
        payable
        auctionActive(auctionItemId)
    {
        AuctionItem storage auctionItem = auctionItems[auctionItemId];
        require(
            msg.value > auctionItem.highestBid,
            "Bid must be greater than the current highest bid"
        );
        require(block.timestamp < auctionItem.endTime, "Auction has ended");

        // Refund the previous bidder
        if (auctionItem.highestBidder != address(0)) {
            BidInfo storage previousBidderInfo = bids[auctionItemId][
                auctionItem.highestBidder
            ];
            payable(auctionItem.highestBidder).transfer(
                previousBidderInfo.amount
            );
            previousBidderInfo.amount = 0; // Set the previous bidder's amount to 0
        }

        // Update highest bid
        auctionItem.highestBid = msg.value;
        auctionItem.highestBidder = msg.sender;

        // Record bid
        bids[auctionItemId][msg.sender] = BidInfo({
            amount: msg.value,
            withdrawn: false
        });

        emit BidPlaced(auctionItemId, msg.sender, msg.value);
    }

    function acceptBid(uint256 auctionItemId)
        external
        onlyAuctionItemOwner(auctionItemId)
        auctionActive(auctionItemId)
    {
        AuctionItem storage auctionItem = auctionItems[auctionItemId];
        require(
            block.timestamp >= auctionItem.endTime,
            "Auction not yet ended"
        );

        // Transfer funds
        address admin = owner();
        uint256 adminFee = (auctionItem.highestBid * marketplaceFee) / 100;
        uint256 sellerProceeds = auctionItem.highestBid - adminFee;

        payable(admin).transfer(adminFee);
        payable(auctionItem.owner).transfer(sellerProceeds);

        // Transfer NFT
        if (auctionItem.isERC721) {
            IERC721(auctionItem.nftContract).transferFrom(
                auctionItem.owner,
                auctionItem.highestBidder,
                auctionItem.tokenId
            );
        } else {
            IERC1155(auctionItem.nftContract).safeTransferFrom(
                auctionItem.owner,
                auctionItem.highestBidder,
                auctionItem.tokenId,
                1,
                ""
            );
        }

        // Remove item from auction
        delete auctionItems[auctionItemId];
        // delete bids[auctionItemId];

        emit AuctionItemSold(
            auctionItemId,
            auctionItem.highestBidder,
            auctionItem.highestBid
        );
    }

    function withdrawBid(uint256 auctionItemId)
        external
        auctionActive(auctionItemId)
    {
        BidInfo storage bidInfo = bids[auctionItemId][msg.sender];
        require(bidInfo.amount > 0, "No active bid");

        // Refund the bidder if they are not the highest bidder and have not yet withdrawn
        if (
            msg.sender != auctionItems[auctionItemId].highestBidder &&
            !bidInfo.withdrawn
        ) {
            payable(msg.sender).transfer(bidInfo.amount);
            bidInfo.withdrawn = true;
        }

        emit BidPlaced(auctionItemId, msg.sender, 0);
    }

    function getBidAmount(uint256 auctionItemId)
        external
        view
        returns (uint256)
    {
        return bids[auctionItemId][msg.sender].amount;
    }

    function placeUnlistedBid(uint256 unlistedItemId) external payable {
        UnlistedNFT storage unlistedNFT = unlistedNFTs[unlistedItemId];
        require(unlistedNFT.isActive, "NFT is not unlisted");
        require(msg.value > 0, "Bid amount must be greater than 0");

        uint256 unlistedBidId = _getNextUnlistedBidId();
        BidInfo storage bidInfo = unlistedItemBids[unlistedItemId][msg.sender];
        bidInfo.amount = msg.value;
        bidInfo.withdrawn = false;

        emit BidPlaced(unlistedBidId, msg.sender, msg.value);
    }

    // Withdraw bid for an unlisted NFT
    function withdrawUnlistedBid(uint256 unlistedBidId) external {
        BidInfo storage bidInfo = unlistedItemBids[unlistedBidId][msg.sender];
        require(bidInfo.amount > 0 && !bidInfo.withdrawn, "No active bid");

        payable(msg.sender).transfer(bidInfo.amount);
        bidInfo.amount = 0;
        bidInfo.withdrawn = true;

        emit BidWithdrawn(unlistedBidId, msg.sender, bidInfo.amount);
    }

    // Accept bid for an unlisted NFT
    function acceptUnlistedBid(uint256 unlistedBidId) external onlyOwner {
        BidInfo storage bidInfo = unlistedItemBids[unlistedBidId][msg.sender];
        require(bidInfo.amount > 0 && !bidInfo.withdrawn, "No active bid");

        payable(msg.sender).transfer(bidInfo.amount);
        bidInfo.amount = 0;
        bidInfo.withdrawn = true;

        // Transfer the NFT to the bidder
        UnlistedNFT storage unlistedNFT = unlistedNFTs[unlistedBidId];
        if (_checkIsERC721(unlistedNFT.nftContract)) {
            IERC721(unlistedNFT.nftContract).transferFrom(
                address(this),
                msg.sender,
                unlistedNFT.tokenId
            );
        } else {
            IERC1155(unlistedNFT.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                unlistedNFT.tokenId,
                1,
                ""
            );
        }

        unlistedNFT.isActive = false;

        emit BidAccepted(unlistedBidId, msg.sender, bidInfo.amount);
    }

    function addFunds() external payable onlyOwner nonReentrant {}

    function withdrawFunds(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient funds");
        payable(owner()).transfer(amount);
    }

    function setMarketplaceFee(uint256 newFee) external onlyOwner nonReentrant {
        require(newFee <= 100, "Fee should be in percentage");
        marketplaceFee = newFee;
    }

    // Internal functions
    function _checkIsERC721(address nftContract) internal view returns (bool) {
        // Check if the contract supports ERC721
        (bool success, ) = nftContract.staticcall(
            abi.encodeWithSelector(IERC721.ownerOf.selector, 1)
        );
        return success;
    }
}

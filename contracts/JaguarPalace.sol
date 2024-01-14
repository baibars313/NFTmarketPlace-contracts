// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./safeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    using SafeMath for uint256;
    address tokenAddress;
    // Define the state struct for users
    struct User {
        address walletAddress;
        bool isBlacklisted;
    }

    constructor() Ownable(msg.sender) {}

    // Define the state struct for items
    struct Item {
        address owner;
        uint256 priceInEth;
        uint256 priceInToken;
        string uri;
        bool isUnlimited; // If true, the item can be sold unlimited times until sold out
        bool isSold;
        uint256 saleEndTime; // Set to 0 for unlimited sale time
    }

    // Define the state struct for bought items
    struct BoughtItem {
        uint256 itemId;
        address buyer;
    }

    function AddToken(address newOwner) public onlyOwner {
        tokenAddress = newOwner;
    }

    // Define the state struct for blacklisted users
    struct BlacklistUser {
        bool isBlacklisted;
    }

    // Mapping of user addresses to user data
    mapping(address => User) public users;

    // Mapping of item IDs to item data
    mapping(uint256 => Item) public items;

    // Mapping of bought item IDs to bought item data
    mapping(uint256 => BoughtItem) public boughtItems;

    // Mapping of blacklisted user addresses to blacklist data
    mapping(address => BlacklistUser) public blacklist;

    // Event emitted when a new item is created
    event ItemCreated(uint256 itemId);

    // Event emitted when an item is bought
    event ItemBought(uint256 itemId, address buyer);

    // Event emitted when an item is marked as sold
    event ItemMarkedAsSold(uint256 itemId);

    // Event emitted when an item is marked as unsold
    event ItemMarkedAsUnsold(uint256 itemId);

    // Event emitted when the contract owner is changed
    event OwnerChanged(address newOwner);

    // Event emitted when the transaction fee is changed
    event FeeChanged(uint256 newFee);

    // Event emitted when a user is blacklisted
    event UserBlacklisted(address user);

    // Event emitted when a user is whitelisted
    event UserWhitelisted(address user);

    // Admin function to change the contract owner
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        emit OwnerChanged(_newOwner);
        transferOwnership(_newOwner);
    }

    // Admin function to change the transaction fee
    function changeFee(uint256 _newFee) external onlyOwner {
        emit FeeChanged(_newFee);
    }

    // Admin function to mark an item as sold by ID
    function markItemAsSold(uint256 _itemId) external onlyOwner {
        require(
            items[_itemId].owner != address(0),
            "Item with this ID does not exist"
        );
        require(!items[_itemId].isSold, "Item is already sold");
        items[_itemId].isSold = true;
        emit ItemMarkedAsSold(_itemId);
    }

    // Admin function to mark an item as unsold by ID
    function markItemAsUnsold(uint256 _itemId) external onlyOwner {
        require(
            items[_itemId].owner != address(0),
            "Item with this ID does not exist"
        );
        require(items[_itemId].isSold, "Item is not sold");
        items[_itemId].isSold = false;
        emit ItemMarkedAsUnsold(_itemId);
    }

    // Admin function to blacklist a user
    function blacklistUser(address _user) external onlyOwner {
        require(
            users[_user].walletAddress != address(0),
            "User with this address does not exist"
        );
        users[_user].isBlacklisted = true;
        emit UserBlacklisted(_user);
    }

    // Admin function to whitelist a user
    function whitelistUser(address _user) external onlyOwner {
        require(
            users[_user].walletAddress != address(0),
            "User with this address does not exist"
        );
        users[_user].isBlacklisted = false;
        emit UserWhitelisted(_user);
    }

    // Function to create or update an item
    function createItem(
        uint256 _itemId,
        uint256 _priceInEth,
        uint256 _priceInToken,
        string memory _uri,
        bool _isUnlimited,
        uint256 _saleEndTime
    ) external {
        Item storage item = items[_itemId];

        // Check if the item exists
        if (item.owner != address(0)) {
            // Item exists, check if the caller is the owner
            require(
                item.owner == msg.sender,
                "Only the owner can update the item"
            );
        }

        // Update/Create the item details
        items[_itemId] = Item({
            owner: msg.sender,
            priceInEth: _priceInEth,
            priceInToken: _priceInToken,
            uri: _uri,
            isUnlimited: _isUnlimited,
            isSold: false,
            saleEndTime: block.timestamp + _saleEndTime
        });

        emit ItemCreated(_itemId);
    }

    // Function to buy an item with ETH
    function buyWithEth(uint256 _itemId) external payable {
        require(
            !users[msg.sender].isBlacklisted,
            "You are blacklisted and cannot make purchases"
        );
        Item storage item = items[_itemId];
        require(item.owner != address(0), "Item with this ID does not exist");
        require(!item.isSold, "Item has already been sold");
        require(
            item.saleEndTime == 0 || block.timestamp <= item.saleEndTime,
            "Sale has ended"
        );

        uint256 ethPrice = item.priceInEth;
        require(msg.value >= ethPrice, "Insufficient ETH sent");

        // Transfer the fee to the contract owner
        uint256 fee = ethPrice.mul(5).div(100); // Assuming a 5% fee
        payable(owner()).transfer(fee);

        // Transfer the remaining value to the user
        payable(item.owner).transfer(msg.value.sub(fee));

        // Mark the item as sold
        
        
        // Record the bought item
        boughtItems[_itemId] = BoughtItem({itemId: _itemId, buyer: msg.sender});

        emit ItemBought(_itemId, msg.sender);
    }

    // Function to buy an item with ERC20 token
    function buyWithToken(uint256 _itemId, uint256 _tokenAmount) external {
        require(
            !users[msg.sender].isBlacklisted,
            "You are blacklisted and cannot make purchases"
        );
        Item storage item = items[_itemId];
        require(item.owner != address(0), "Item with this ID does not exist");
        require(!item.isSold, "Item has already been sold");
        require(
            item.saleEndTime == 0 || block.timestamp <= item.saleEndTime,
            "Sale has ended"
        );

        // Assume you have a ERC20 token contract address stored in a variable named "tokenAddress"
        IERC20 token = IERC20(tokenAddress);
        // Transfer tokens from the buyer to the contract
        require(
            token.transferFrom(msg.sender, address(this), _tokenAmount),
            "Token transfer failed"
        );

        // Transfer the fee to the contract owner
        // Transfer the fee to the contract owner
        uint256 fee = _tokenAmount.mul(5).div(100); // Assuming a 5% fee
        require(token.transfer(owner(), fee), "Token transfer failed");

        // Transfer the remaining value to the user
        require(
            token.transfer(item.owner, _tokenAmount.sub(fee)),
            "Token transfer failed"
        );

        // Mark the item as sold
        item.isSold = true;

        // Record the bought item
        boughtItems[_itemId] = BoughtItem({itemId: _itemId, buyer: msg.sender});

        emit ItemBought(_itemId, msg.sender);
    }
}

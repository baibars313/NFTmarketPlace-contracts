# NFT Marketplace Smart Contract

## Overview

This Ethereum smart contract is a decentralized marketplace tailored for Non-Fungible Tokens (NFTs), providing a comprehensive suite of features for buying, selling, and auctioning unique digital assets. Additionally, it introduces the concept of unlisted NFTs with bidding functionality, offering users a versatile platform to engage with digital collectibles.

## Features

### 1. Fixed-Price Sales

- **Listing Items:** Users can effortlessly list NFTs for sale by providing the contract address, token ID, and a specified price.
- **Purchase Mechanism:** Buyers can seamlessly acquire NFTs by executing the `purchase` function, initiating both the fund transfer and NFT ownership transfer.

### 2. Auctions

- **Auction Creation:** Sellers can set up auctions using the `createAuction` function, specifying the contract address, token ID, starting price, duration, and the NFT type (ERC721 or ERC1155).
- **Bid Placement:** Bidders can actively participate in ongoing auctions by placing bids using the `placeBid` function.
- **Completion and Settlement:** Upon the conclusion of an auction, the seller can execute `acceptBid` to complete the transaction, transferring both funds and NFT ownership to the highest bidder.

### 3. Unlisted NFTs

- **Unlisting NFTs:** Owners can opt to unlist NFTs, opening them up for bids through the `placeUnlistedBid` function.
- **Bidding on Unlisted NFTs:** Users can place bids on unlisted NFTs, fostering a dynamic environment.
- **Bid Acceptance:** The owner can accept the highest bid using `acceptUnlistedBid`, facilitating the transfer of the NFT and the corresponding funds.

### 4. Marketplace Fee

- **Configurable Fee:** The smart contract incorporates a customizable marketplace fee (expressed as a percentage) on transactions.

### 5. Admin Functions

- **Funds Management:** The contract owner possesses exclusive rights to add funds (`addFunds`) and withdraw funds (`withdrawFunds`).
- **Marketplace Fee Adjustment:** The owner can dynamically set or update the marketplace fee through the `setMarketplaceFee` function.

## How to Use

### Fixed-Price Sales

1. Utilize `listForSale` to place an NFT for sale by providing its contract address, token ID, and the desired price.
2. Interested buyers can execute `purchase` with the item ID to complete the purchase transaction.

### Auctions

1. Initiate an auction with `createAuction` by specifying the contract address, token ID, starting price, duration, and NFT type.
2. Bidders actively participate in ongoing auctions by calling `placeBid`.
3. Upon the auction's conclusion, the seller executes `acceptBid` to finalize the auction, transferring funds and NFT ownership.

### Unlisted NFTs

1. Owners can unlist an NFT using `placeUnlistedBid`.
2. Users bid on unlisted NFTs, with the owner able to accept the highest bid through `acceptUnlistedBid`.

### Admin Functions

- Contract owners can add funds using `addFunds`.
- Withdraw funds using `withdrawFunds`.
- Adjust the marketplace fee with `setMarketplaceFee`.

## Important Notes

- Ensure your Ethereum wallet is connected for interactions.
- Deploy on Ethereum Mainnet or Testnets.

## Live Demo

[Explore the live demo of the NFT Marketplace](<LIVE_DEMO_LINK>)

## License

This smart contract is open-source and released under the MIT License. Feel free to explore, contribute, and integrate it into your projects.


# NFT MarketPlace Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

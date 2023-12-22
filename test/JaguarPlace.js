const ethers = require('ethers');

// Replace with the actual contract address and ABI
const contractAddress = 'YOUR_CONTRACT_ADDRESS';
const abi = []; // Replace with the actual ABI array

// Replace with your Ethereum node URL
const nodeUrl = 'https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID';

// Replace with your private key
const privateKey = 'YOUR_PRIVATE_KEY';

const provider = new ethers.providers.JsonRpcProvider(nodeUrl);
const wallet = new ethers.Wallet(privateKey, provider);

const contract = new ethers.Contract(contractAddress, abi, wallet);

// Function to change the contract owner
async function changeOwner(newOwner) {
    const tx = await contract.changeOwner(newOwner);
    await tx.wait();
}

// Function to change the transaction fee
async function changeFee(newFee) {
    const tx = await contract.changeFee(newFee);
    await tx.wait();
}

// Function to mark an item as sold by ID
async function markItemAsSold(itemId) {
    const tx = await contract.markItemAsSold(itemId);
    await tx.wait();
}

// Function to mark an item as unsold by ID
async function markItemAsUnsold(itemId) {
    const tx = await contract.markItemAsUnsold(itemId);
    await tx.wait();
}

// Function to blacklist a user
async function blacklistUser(user) {
    const tx = await contract.blacklistUser(user);
    await tx.wait();
}

// Function to whitelist a user
async function whitelistUser(user) {
    const tx = await contract.whitelistUser(user);
    await tx.wait();
}

// Function to create a new item
async function createItem(itemId, priceInEth, priceInToken, uri, isUnlimited, saleEndTime) {
    const tx = await contract.createItem(itemId, priceInEth, priceInToken, uri, isUnlimited, saleEndTime);
    await tx.wait();
}

// Function to buy an item with ETH
async function buyWithEth(itemId, value) {
    const overrides = { value: ethers.utils.parseEther(value.toString()) };
    const tx = await contract.buyWithEth(itemId, overrides);
    await tx.wait();
}

// Function to buy an item with ERC20 token
async function buyWithToken(itemId, tokenAmount) {
    const tx = await contract.buyWithToken(itemId, tokenAmount);
    await tx.wait();
}

// Example usage
// Replace the values with your actual data
changeOwner('NEW_OWNER_ADDRESS');
changeFee(10);
markItemAsSold(1);
markItemAsUnsold(2);
blacklistUser('USER_ADDRESS');
whitelistUser('USER_ADDRESS');
createItem(1, 1, 1, 'URI', true, 0);
buyWithEth(1, 1);
buyWithToken(2, 100);

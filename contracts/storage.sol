// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


contract Sale is ERC1155, Ownable {
    string private  market;
    mapping(uint256 => string) private _uris;

    uint256 MarketFee;

    constructor() ERC1155("") Ownable(msg.sender) {}

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory _Uri) public {
        require(bytes(_uris[tokenId]).length == 0, "Cannot set uri twice");
        _uris[tokenId] = _Uri;
    }

    function changeMarket(string memory _market) public onlyOwner {
        market = _market;
    }
    

    function mintToken(string memory _uri, uint256 _tokenIds, string memory _password) external {
        console.log(msg.sender);
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(market)), "Only the market can mint tokens");
        _mint(owner(), _tokenIds, 1, "");
        setTokenUri(_tokenIds, _uri);
        _tokenIds += 1;
    }

    function burn(uint256 tokenId, string memory _password) external {
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(market)), "Only the market can mint tokens");
        _burn(owner(), tokenId, 1);
    }
}



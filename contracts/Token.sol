// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyERC1155 is ERC1155, Ownable {
    using Strings for uint256;

    string public baseUri;

    constructor(string memory _baseUri)Ownable(msg.sender) ERC1155(_baseUri) {
        baseUri = _baseUri;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function uri(uint256 tokenId) override public  view returns (string memory) {
        return string(abi.encodePacked(baseUri, "/", tokenId.toString(), ".json"));
    }

    function mint( uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(msg.sender, id, amount, data);
    }

    function mintBatch( uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyOwner {
        _mintBatch(msg.sender, ids, amounts, data);
    }
}

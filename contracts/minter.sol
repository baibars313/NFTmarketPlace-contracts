// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Minter is ERC1155, Ownable {
    uint256 public _tokenIds = 0;

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

    function mintToken(uint256 _amount, string memory _uri)public{
        require(_amount != 0, "supplu should be more than zerro");
        _mint(msg.sender, _tokenIds, _amount, "");
        setTokenUri(_tokenIds, _uri);
        _tokenIds += 1;
    }
}

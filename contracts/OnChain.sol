// SPDX-License-Identifier: MIT
// Author: Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/metadata.sol";

interface IOnChainRenderer {
    function tokenURI(uint256 tokenId_, metadataTypes.metadataStruct memory metadata_) external view returns (string memory);
}

contract OnChain is Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Enums
    enum ContractState { WAITING, PRESALE, PUBLIC }
    
    // Variables
    bool public _berserk = true;
    uint256 public _maxSupply = 10000;
    address public _renderer;
    ContractState public currentState = ContractState.PUBLIC;

    // Mappings
    mapping(address => bool) public _stakingAddresses;
    mapping(address => bool) public _hasAlreadyMinted;
    mapping(uint256 => metadataTypes.metadataStruct) public _metadataMapping;

    // Owner-only Functions
    constructor() ERC721("On-Chain", "OC") {}

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
    }

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBerserk(bool berserk_) external onlyOwner {
        _berserk = berserk_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        _maxSupply = maxSupply_;
    }

    function setRenderer(address renderer_) external onlyOwner {
        _renderer = renderer_;
    }

    // Public Functions
    function safeMint() public nonReentrant {
        require(currentState != ContractState.WAITING);
        require(!_hasAlreadyMinted[msg.sender]);
        require(balanceOf(msg.sender) == 0);

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply);
        
        _tokenIdCounter.increment();

        _metadataMapping[tokenId].faction = 1;
        _metadataMapping[tokenId].fusionCount = 7;

        if(currentState == ContractState.PUBLIC) {
            _safeMint(msg.sender, tokenId);
        } else {
            // TODO Whitelisting
            _safeMint(msg.sender, tokenId);
        }

        _hasAlreadyMinted[msg.sender] = true;
    }

    // Overriding OpenZeppelin-ERC721 _transfer function! Requires flattening to gain access to ERC-721 variables.
    // You need to manually change _balances and _owners variables from private to internal in ERC-721.sol
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(ERC721.ownerOf(tokenId) == from);
        require(to != address(0));
        require(from != to);

        _beforeTokenTransfer(from, to, tokenId);

        if(balanceOf(to) == 0 || _stakingAddresses[to] || !_berserk) { // Transaction proceeds as normal
            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;
        } else {
            _metadataMapping[tokenId].fusionCount += _metadataMapping[tokenId].fusionCount;
            burn(tokenId);
        }

        emit Transfer(from, to, tokenId);
    }

    // Solidity-Required Functions 
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId));

        IOnChainRenderer renderer = IOnChainRenderer(_renderer);
        
        return renderer.tokenURI(_tokenId, _metadataMapping[_tokenId]);
    }
}
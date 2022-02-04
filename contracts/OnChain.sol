// SPDX-License-Identifier: MIT
// Author: Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "./interfaces/metadata.sol";

interface IOnChainRenderer {
    function tokenURI(uint256 tokenId_, metadataTypes.metadataStruct memory metadata_) external view returns (string memory);
}

contract OnChain is ERC721Burnable, Pausable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Enums
    enum MintState { WAITING, PRESALE, PUBLIC }
    
    // Variables
    bytes32 public _reapersRootHash;
    bytes32 public _trickstersRootHash;
    bool public _berserk = true;
    uint256 public _maxSupply = 10000;
    uint256 public _generation = 0;
    address public _renderer;
    address public immutable openSeaProxy = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // OpenSea Proxy for Gasless Listing
    MintState public _mintState = MintState.WAITING;

    // Mappings
    mapping(address => bool) public _stakingAddresses;
    mapping(address => bool) public _hasAlreadyMinted;
    mapping(uint256 => metadataTypes.metadataStruct) public _metadataMapping;
    mapping(address => bool) proxyToApproved;

    // Owner-only Functions
    constructor() ERC721("On-Chain", "OC") {}

    function changeMintState(MintState mintState_) external onlyOwner {
        _mintState = mintState_;
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

    function setGeneration(uint256 generation_) external onlyOwner {
        _generation = generation_;
    }

    function setRenderer(address renderer_) external onlyOwner {
        _renderer = renderer_;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    function setRootHashes(bytes32 reapersHash_, bytes32 trickstersHash_) external onlyOwner {
    _reapersRootHash = reapersHash_;
    _trickstersRootHash = trickstersHash_;
  }

    // Public Functions
    function safeMint(bytes32[] calldata proof_) public nonReentrant {
        require(_mintState != MintState.WAITING);
        require(!_hasAlreadyMinted[msg.sender]);
        require(balanceOf(msg.sender) == 0);

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply);
        
        _tokenIdCounter.increment();

        if(_mintState == MintState.PRESALE) {
            require(isWhitelisted(proof_, _reapersRootHash, msg.sender) || isWhitelisted(proof_, _trickstersRootHash, msg.sender), "Not whitelisted.");
            if (isWhitelisted(proof_, _reapersRootHash, msg.sender)) {
                _metadataMapping[tokenId].faction = 0;
            } else {
                _metadataMapping[tokenId].faction = 1;
            }
            _safeMint(msg.sender, tokenId);
        } else {
            _metadataMapping[tokenId].faction = uint(keccak256(abi.encodePacked(msg.sender))) % 2;
            _safeMint(msg.sender, tokenId);
        }

        _hasAlreadyMinted[msg.sender] = true;
    }

    // Overriding OpenZeppelin-ERC721 function!
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

    // Overriding OpenZeppelin-ERC721 function!
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(openSeaProxy);
        
        if (address(proxyRegistry.proxies(_owner)) == operator || proxyToApproved[operator]) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId));

        IOnChainRenderer renderer = IOnChainRenderer(_renderer);
        
        return renderer.tokenURI(_tokenId, _metadataMapping[_tokenId]);
    }
}

function isWhitelisted(bytes32[] calldata proof_, bytes32 tree_, address sender_) pure returns (bool) {
    return MerkleProof.verify( proof_, tree_, keccak256(abi.encodePacked(sender_)));           
}

// Implemented for Gasless OpenSea listing
contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
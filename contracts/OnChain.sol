// SPDX-License-Identifier: MIT
// Author: Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/Metadata.sol";

contract OnChain is ERC721Burnable, Pausable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Enums
    enum MintState { WAITING, PRESALE, PUBLIC }
    
    // Variables
    string public _base = 'https://titanbornes.herokuapp.com/api/image/';
    bytes32 public _reapersRootHash;
    bytes32 public _trickstersRootHash;
    bool public _berserk = true;
    uint256 public _maxSupply = 10000;
    address public immutable openSeaProxy = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // OpenSea Rinkeby Proxy for Gasless Listing
    MintState public _mintState = MintState.PRESALE;

    // Mappings
    mapping(address => bool) public _stakingAddresses;
    mapping(address => bool) public _hasMinted;
    mapping(address => uint256[]) public _tokens;
    mapping(uint256 => metadataTypes.metadataStruct) public _metadataMapping;
    mapping(address => bool) _approvedProxies;

    // Owner-only Functions
    constructor() ERC721("Semi-OnChain-Four", "SOC4") {}

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

    function flipProxyState(address proxyAddress_) public onlyOwner {
        _approvedProxies[proxyAddress_] = !_approvedProxies[proxyAddress_];
    }

    function setRootHashes(bytes32 reapersHash_, bytes32 trickstersHash_) external onlyOwner {
        _reapersRootHash = reapersHash_;
        _trickstersRootHash = trickstersHash_;
    }

    // Public Functions
    function safeMint(bytes32[] calldata proof_) public nonReentrant {
        require(_mintState != MintState.WAITING);
        require(!_hasMinted[msg.sender]);
        require(balanceOf(msg.sender) == 0);

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply);
        
        _tokenIdCounter.increment();

        if(_mintState == MintState.PRESALE) {
            require(isWhitelisted(proof_, _reapersRootHash, msg.sender) || isWhitelisted(proof_, _trickstersRootHash, msg.sender), "Not whitelisted.");
            if (isWhitelisted(proof_, _reapersRootHash, msg.sender)) {
                _metadataMapping[tokenId].faction = 'Reapers';
            } else {
                _metadataMapping[tokenId].faction = 'Tricksters';
            }
            _safeMint(msg.sender, tokenId);
        } else {
            _metadataMapping[tokenId].faction = uint(keccak256(abi.encodePacked(msg.sender))) % 2 == 0 ? 'Reapers' : 'Tricksters';
            _safeMint(msg.sender, tokenId);
        }

        _tokens[msg.sender].push(tokenId);
        _hasMinted[msg.sender] = true;
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
            _tokens[to].push(tokenId);
        } else {
            _metadataMapping[_tokens[to][0]].fusionCount += _metadataMapping[tokenId].fusionCount;
            burn(tokenId);
        }

        delete _tokens[from][0];
        emit Transfer(from, to, tokenId);
    }

    // Overriding OpenZeppelin-ERC721 function!
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(openSeaProxy);
        
        if (address(proxyRegistry.proxies(_owner)) == operator || _approvedProxies[operator]) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_));
        
        string memory _namePrefix = "Titanborne #";
        string memory _description = "On-Chain Storytelling Experiment.";
        string memory _traits = string(abi.encodePacked('"attributes": [{"trait_type": "Fusion Count","value": ', toString(_metadataMapping[tokenId_].fusionCount),'},{"trait_type": "Faction","value": "', _metadataMapping[tokenId_].faction,'"}]'));

        string memory json = string(abi.encodePacked('{"name": "', _namePrefix, toString(tokenId_), '", "description": "', _description, '", "image": "', 'https://boryoku-dragonz-public.s3.us-east-2.amazonaws.com/legendaries/king.gif', '",', _traits,' }'));

        return string(abi.encodePacked('data:application/json;utf8,', json));
    }

    function isWhitelisted(bytes32[] calldata proof_, bytes32 tree_, address sender_) public pure returns (bool) {
        return MerkleProof.verify( proof_, tree_, keccak256(abi.encodePacked(sender_)));           
    }

    function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
}



// Implemented for Gasless OpenSea listing
contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
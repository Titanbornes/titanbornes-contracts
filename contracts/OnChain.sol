// SPDX-License-Identifier: MIT
// Author: @Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OnChain is ERC721Burnable, Pausable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Enums
    enum MintState { WAITING, PRESALE, PUBLIC }

    // Structs
    struct attributes {
        uint256 fusionCount;
        uint256 generation;
        string faction;
        string name;
        string description;
    }
    
    // Variables
    string public _base = 'https://titanbornes.herokuapp.com/api/tokenURI/';
    bytes32 public _reapersRoot;
    bytes32 public _trickstersRoot;
    bool public _berserk = true;
    uint256 public _generation = 0; // Will only be used if voted on by the DAO 
    uint256 public _mintPrice = 0;
    bool public _characterized;
    uint256 public _maxSupply = 10000;
    address public immutable openSeaProxy = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // OpenSea Rinkeby Proxy for Gasless Listing
    MintState public _mintState = MintState.PRESALE;

    // Mappings
    mapping(address => bool) public _stakingAddresses;
    mapping(address => bool) _approvedProxies;
    mapping(address => bool) public _hasMinted;
    mapping(address => uint256[]) public _tokens;
    mapping(uint256 => attributes) public _attributes;

    // Owner-only Functions
    constructor() ERC721("Semi-OnChain-Five", "SOC5") {}

    function changeMintState(MintState value) external onlyOwner {
        _mintState = value;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBerserk(bool value) external onlyOwner {
        _berserk = value;
    }

    function modifyGen(uint256 value) external onlyOwner {
        _generation = value;
    }

    function characterize(uint256[] calldata indexes_, string[] calldata names_, string[] calldata descriptions_) external onlyOwner {
        _characterized = true;
        for (uint256 i = 0; i < indexes_.length; i++) {
            _attributes[indexes_[i]].name = names_[i];
            _attributes[indexes_[i]].description = descriptions_[i];
        }
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        _maxSupply = value;
    }

    function flipProxyState(address value) external onlyOwner {
        _approvedProxies[value] = !_approvedProxies[value];
    }

    function setRootHashes(bytes32 reapers_, bytes32 tricksters_) external onlyOwner {
        _reapersRoot = reapers_;
        _trickstersRoot = tricksters_;
    }

    // Public Functions
    function safeMint(bytes32[] calldata proof_) public payable nonReentrant {
        require(_mintState != MintState.WAITING, 'MINTING DISABLED');
        require(!_hasMinted[msg.sender], 'ALREADY MINTED');
        require(balanceOf(msg.sender) == 0, 'ALREADY OWNS');
        require(msg.value == _mintPrice, 'WRONG VALUE');

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _maxSupply, 'ALL MINTED');
        
        _tokenIdCounter.increment();

        if(_mintState == MintState.PRESALE) {
            require(isWhitelisted(proof_, _reapersRoot, msg.sender) || isWhitelisted(proof_, _trickstersRoot, msg.sender), "NOT WHITELISTED");
            if (isWhitelisted(proof_, _reapersRoot, msg.sender)) {
                _attributes[tokenId].faction = 'Reapers';
            } else {
                _attributes[tokenId].faction = 'Tricksters';
            }
            _safeMint(msg.sender, tokenId);
        } else {
            _attributes[tokenId].faction = uint(keccak256(abi.encodePacked(msg.sender))) % 2 == 0 ? 'Reapers' : 'Tricksters';
            _safeMint(msg.sender, tokenId);
        }

        _attributes[tokenId].generation = _generation;
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
        require(ERC721.ownerOf(tokenId) == from, 'NOT OWNER');
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
            _attributes[_tokens[to][0]].fusionCount == 0 ? _attributes[_tokens[to][0]].fusionCount += 1 : _attributes[_tokens[to][0]].fusionCount+= _attributes[tokenId].fusionCount;
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
        require(_exists(tokenId_), 'NONEXISTENT');
        
        string memory _namePrefix = _characterized ? _attributes[tokenId_].name : "Token #";
        string memory _description = _characterized ? _attributes[tokenId_].description : "On-Chain Storytelling Experiment.";
        string memory _traits = string(abi.encodePacked('"attributes": [{"trait_type": "Fusion Count","value": ', toString(_attributes[tokenId_].fusionCount),'},{"trait_type": "Faction","value": "', _attributes[tokenId_].faction,'"}]'));

        string memory json = string(abi.encodePacked('{"name": "', _namePrefix, toString(tokenId_), '", "description": "', _description, '", "image": "', _base, toString(_attributes[tokenId_].fusionCount),'.png', '",', _traits,' }'));

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
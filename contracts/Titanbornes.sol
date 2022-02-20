// SPDX-License-Identifier: MIT
// Author: @Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Titanbornes is ERC721, Pausable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Enums
    enum MintState { WAITING, PRESALE, PUBLIC }

    // Structs
    struct attributesStruct {
        uint256 fusionCount;
        uint256 generation;
        string faction;
    }

    // Events
    event Fusion(uint256 tokenId, uint256 fusionCount);
    event Mint(address to, uint256 tokenId, uint256 generation, string faction);
    
    // Constants
    address public immutable OSProxy = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // OpenSea Rinkeby Proxy for Gasless Listing

    // Variables
    address public royaltyReceiver = 0xF7978705D1635818F996C25950b3dE622174DD1e;
    bool public fuse = true; // Controls the fusion logic flow
    bool public characterized; 
    string public endpoint = "https://titanbornes.herokuapp.com/api/metadata/";
    bytes32 public reapersRoot = 0xfdd8a991eaa70924a5426f007fb2c9394dbe2eacd4a818a60803652a456f0861; // Merkle Tree Root for the Reapers Faction Whitelist
    bytes32 public trickstersRoot = 0x6dc9c21acc3f001441ba4427a8aa0ba5244b5873d0a59acd62e9f221fd05c80e; // Merkle Tree Root for the Tricksters Faction Whitelist
    uint256 public generation = 0; // Will only be used if voted on by the DAO, if and when supply drops to triple-digits.
    uint256 public mintPrice = 0;
    uint256 public maxSupply = 10000;
    uint256 public royaltyFactor = 50;     // Royalty amount is %5, see royaltyInfo function
    MintState public mintState = MintState.PRESALE;

    // Mappings
    mapping(address => bool) public stakingAddresses;
    mapping(address => bool) public approvedProxies;
    mapping(address => mapping (uint256 => bool)) public hasMintedGen;
    mapping(address => uint256[]) public tokensOwners;
    mapping(uint256 => attributesStruct) public attributes;

    // Owner-only Functions
    constructor() ERC721("Fusion-Eventful-Two", "FE") {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMintState(MintState value) external onlyOwner {
        mintState = value;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setEndpoint(string calldata value) external onlyOwner {
        endpoint = value;
    }

    function setPrice(uint256 value) external onlyOwner {
        mintPrice = value;
    }

    function setRoyaltyInfo(uint256 factor, address receiver) external onlyOwner {
        royaltyFactor = factor;
        royaltyReceiver = receiver;
    }

    function flipFuse() external onlyOwner {
        fuse = !fuse;
    }

    function modifyGen(uint256 value) external onlyOwner {
        generation = value;
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        maxSupply = value;
    }

    function setStakingAddresses(address value) external onlyOwner {
        stakingAddresses[value] = !stakingAddresses[value];
    }

    function setProxies(address value) external onlyOwner {
        approvedProxies[value] = !approvedProxies[value];
    }

    function setRootHashes(bytes32 rValue, bytes32 tValue) external onlyOwner {
        reapersRoot = rValue;
        trickstersRoot = tValue;
    }

    // Protected Functions
    function incrementFusionCount(uint256 tokenId) external nonReentrant {
        require(approvedProxies[msg.sender], 'UNAUTHORIZED');
        require(!fuse, 'NOT YET');
        attributes[tokenId].fusionCount++;
        emit Fusion(tokenId, attributes[tokenId].fusionCount);
    }

    // Public Functions
    function safeMint(bytes32[] calldata proof) public payable nonReentrant {
        require(mintState != MintState.WAITING, 'MINTING DISABLED');
        require(!hasMintedGen[msg.sender][generation], 'ALREADY MINTED');
        require(balanceOf(msg.sender) == 0, 'ALREADY OWNS');
        require(msg.value == mintPrice, 'WRONG VALUE');

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, 'ALL MINTED');
        
        _tokenIdCounter.increment();

        if(mintState == MintState.PRESALE) {
            require(isWhitelisted(proof, reapersRoot, msg.sender) || isWhitelisted(proof, trickstersRoot, msg.sender), "NOT WHITELISTED");
            if (isWhitelisted(proof, reapersRoot, msg.sender)) {
                attributes[tokenId].faction = 'Reapers';
            } else {
                attributes[tokenId].faction = 'Tricksters';
            }
            _safeMint(msg.sender, tokenId);
        } else {
            attributes[tokenId].faction = uint(keccak256(abi.encodePacked(msg.sender))) % 2 == 0 ? 'Reapers' : 'Tricksters';
            _safeMint(msg.sender, tokenId);
        }

        attributes[tokenId].fusionCount = 1;
        attributes[tokenId].generation = generation;
        tokensOwners[msg.sender].push(tokenId);
        hasMintedGen[msg.sender][generation] = true;
        emit Mint(msg.sender, tokenId, generation, attributes[tokenId].faction);
    }

    // Relies on manually changing _balances and _owners variables from private to internal in ERC-721.sol
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(ERC721.ownerOf(tokenId) == from, 'NOT OWNER');
        require(to != address(0), 'ILLEGAL TRANSFER');
        require(from != to, 'ILLEGAL TRANSFER');

        _beforeTokenTransfer(from, to, tokenId);

        if(balanceOf(to) == 0 || stakingAddresses[to] || !fuse) { // Transaction proceeds as normal
            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;
            tokensOwners[to].push(tokenId);
        } else { // Fusion
            if (attributes[tokenId].generation < attributes[tokensOwners[to][0]].generation) {
                attributes[tokenId].fusionCount += attributes[tokensOwners[to][0]].fusionCount;
                _burn(tokensOwners[to][0]);
                delete tokensOwners[to][0];
                _owners[tokenId] = to;
                tokensOwners[to].push(tokenId);
                emit Fusion(tokenId, attributes[tokenId].fusionCount);
            } else {
                attributes[tokensOwners[to][0]].fusionCount += attributes[tokenId].fusionCount;
                _burn(tokenId);
                emit Fusion(tokensOwners[to][0], attributes[tokensOwners[to][0]].fusionCount);
            }

        }

        if (stakingAddresses[from] || !fuse) {
            for (uint256 i = 0; i < tokensOwners[from].length; i++) {
                if (tokensOwners[from][i] == tokenId) {
                    delete tokensOwners[from][i];
                }
            }
        } else {
            delete tokensOwners[from][0];
        }
        emit Transfer(from, to, tokenId);
    }

    // Overriding OpenZeppelin-ERC721 function!
    // function isApprovedForAll(address _owner, address operator) public view override returns (bool) {        
    //     OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(OSProxy);

    //     if (address(proxyRegistry.proxies(_owner)) == operator || approvedProxies[operator]) return true;

    //     return super.isApprovedForAll(_owner, operator);
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return endpoint;
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * royaltyFactor) / 1000;
        return (royaltyReceiver, royaltyAmount);
    }   // https://eips.ethereum.org/EIPS/eip-2981

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    function isWhitelisted(bytes32[] calldata proof, bytes32 tree, address sender) public pure returns (bool) {
        return MerkleProof.verify( proof, tree, keccak256(abi.encodePacked(sender)));           
    }
}

// Implemented for Gasless OpenSea listing
contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
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
    struct attrStruct {
        uint256 fusionCount;
        uint256 generation;
        string faction;
        string name;
        string description;
    }

    // Events
    
    // Constants
    address public immutable OSProxy = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; // OpenSea Rinkeby Proxy for Gasless Listing

    // Variables
    address public royaltyReceiver = 0xF7978705D1635818F996C25950b3dE622174DD1e;
    bool public berserk = false;
    bool public characterized; 
    string public endpoint = "https://titanbornes.herokuapp.com/api/tokenURI/";
    bytes32 public reapersRoot = 0xfebd8af968f1cb6788499ac4aa3a9cc32575230f8b1133faff12fdb1ae51a616;
    bytes32 public trickstersRoot = 0xb3619f3a6cdf3c526fb8751da886492b88c62788bfe272351d478548137b6ece;
    uint256 public generation = 0; // Will only be used if voted on by the DAO, if and when supply drops to double-digits.
    uint256 public mintPrice = 0;
    uint256 public maxSupply = 10000;
    uint256 public royaltyFactor = 50;     // Royalty amount is %5, see royaltyInfo function
    MintState public mintState = MintState.PRESALE;

    // Mappings
    mapping(address => bool) public stakingAddresses;
    mapping(address => bool) public approvedProxies;
    mapping(address => bool) public hasMinted;
    mapping(address => uint256[]) public tokensOwners;
    mapping(uint256 => attrStruct) public attributes;

    // Owner-only Functions
    constructor() ERC721("Semi-OnChain-Eventful", "SOC5") {}

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success);
    }

    function changeMintState(MintState value) external onlyOwner {
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

    function flipBerserk() external onlyOwner {
        berserk = !berserk;
    }

    function modifyGen(uint256 value) external onlyOwner {
        generation = value;
    }

    function characterize(bool state, uint256[] calldata indexes, string[] calldata names, string[] calldata descriptions) external onlyOwner {
        characterized = state;
        for (uint256 i = 0; i < indexes.length; i++) {
            attributes[indexes[i]].name = names[i];
            attributes[indexes[i]].description = descriptions[i];
        }
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

    // Public Functions
    function safeMint(bytes32[] calldata proof) public payable nonReentrant {
        require(mintState != MintState.WAITING, 'MINTING DISABLED');
        require(!hasMinted[msg.sender], 'ALREADY MINTED');
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
        hasMinted[msg.sender] = true;
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

        if(balanceOf(to) == 0 || stakingAddresses[to] || !berserk) { // Transaction proceeds as normal
            // Clear approvals from the previous owner
            _approve(address(0), tokenId);

            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;
            tokensOwners[to].push(tokenId);
        } else {
            if (attributes[tokenId].generation < attributes[tokensOwners[to][0]].generation) {
                attributes[tokenId].fusionCount+= attributes[tokensOwners[to][0]].fusionCount;
                burn(tokensOwners[to][0]);
                _owners[tokenId] = to;
                tokensOwners[to].push(tokenId);
            } else {
                attributes[tokensOwners[to][0]].fusionCount+= attributes[tokenId].fusionCount;
                burn(tokenId);
            }
        }

        delete tokensOwners[from][0];
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

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
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
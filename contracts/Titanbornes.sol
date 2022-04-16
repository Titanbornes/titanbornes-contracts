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
    enum MintState { WAITING, MINTING }

    // Structs
    struct attributesStruct {
        uint256 fusionCount;
        uint256 generation;
        string faction;
    }

    // Events
    event Fusion(uint256 tokenId, uint256 fusionCount);
    event Mint(address to, uint256 tokenId, uint256 fusionCount, uint256 generation, string faction);
    
    // Variables
    address public royaltyReceiver = 0xF7978705D1635818F996C25950b3dE622174DD1e;
    string public endpoint = "https://titanbornes.herokuapp.com/api/metadata/";
    bytes32 public reapersRoot = 0xfdd8a991eaa70924a5426f007fb2c9394dbe2eacd4a818a60803652a456f0861;
    bytes32 public trickstersRoot = 0x6dc9c21acc3f001441ba4427a8aa0ba5244b5873d0a59acd62e9f221fd05c80e;
    uint256 public generation = 0; // Will only be used if voted on by the DAO, if and when supply drops to triple-digits.
    uint256 public mintPrice = 0;
    uint256 public maxSupply = 1000;
    uint256 public royaltyFactor = 50;     // Royalty amount is %5, see royaltyInfo function
    MintState public mintState = MintState.WAITING;

    // Mappings
    mapping(address => mapping (uint256 => bool)) public hasMintedGen;
    mapping(address => uint256) public tokensOwners;
    mapping(uint256 => attributesStruct) public attributes;

    // Owner-only Functions
    constructor() ERC721("Fusion-Destination-Stripped", "FDS") {}

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

    function modifyGen(uint256 value) external onlyOwner {
        generation = value;
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        maxSupply = value;
    }

    function setRootHashes(bytes32 r, bytes32 t) external onlyOwner {
        reapersRoot = r;
        trickstersRoot = t;
    }

    // Public Functions
    function mint(bytes32[] calldata factionProof) public payable nonReentrant {
        require(mintState == MintState.MINTING, 'WRONG MINTSTATE');
        require(verifyMerkle(factionProof, reapersRoot, msg.sender) || verifyMerkle(factionProof, trickstersRoot, msg.sender), "NOT WHITELISTED");
        require(!hasMintedGen[msg.sender][generation], 'ALREADY MINTED');
        require(balanceOf(msg.sender) == 0, 'ALREADY OWNS');

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, 'MAX REACHED');
        _tokenIdCounter.increment();

        if (verifyMerkle(factionProof, reapersRoot, msg.sender)) {
            attributes[tokenId].faction = 'Reapers';
        } else {
            attributes[tokenId].faction = 'Tricksters';
        }
        
        require(msg.value == mintPrice, 'WRONG VALUE');
        _safeMint(msg.sender, tokenId);
        
        attributes[tokenId].fusionCount = 1;
        attributes[tokenId].generation = generation;
        tokensOwners[msg.sender] = tokenId;
        hasMintedGen[msg.sender][generation] = true;
        emit Mint(msg.sender, tokenId, attributes[tokenId].fusionCount, generation, attributes[tokenId].faction);
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

        
        if (attributes[tokenId].generation < attributes[tokensOwners[to]].generation) {
            attributes[tokenId].fusionCount += attributes[tokensOwners[to]].fusionCount;
            _burn(tokensOwners[to]);
            delete tokensOwners[to];
            _owners[tokenId] = to;
            tokensOwners[to] = tokenId;
            emit Fusion(tokenId, attributes[tokenId].fusionCount);
        } else {
            attributes[tokensOwners[to]].fusionCount += attributes[tokenId].fusionCount;
            _burn(tokenId);
            emit Fusion(tokensOwners[to], attributes[tokensOwners[to]].fusionCount);
        }
        
        delete tokensOwners[from];
        emit Transfer(from, to, tokenId);
    }

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

    function verifyMerkle(bytes32[] calldata proof, bytes32 tree, address sender) public pure returns (bool) {
        return MerkleProof.verify( proof, tree, keccak256(abi.encodePacked(sender)));           
    }
}
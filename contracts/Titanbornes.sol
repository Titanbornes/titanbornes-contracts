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
    enum MintState { WAITING, PRIVATE, PUBLIC }

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
    address private royaltyReceiver;
    string private endpoint = "https://titanbornes.herokuapp.com/api/metadata/";
    bytes32 private reapersRoot;
    bytes32 private trickstersRoot;
    uint256 private generation = 0;
    uint256 private mintPrice = 0;
    uint256 private maxSupply = 1000;
    uint256 private royaltyFactor = 50;     // Royalty amount is %5, see royaltyInfo function
    MintState public mintState = MintState.WAITING;

    // Mappings
    mapping(address => mapping (uint256 => bool)) private hasMintedGen;
    mapping(address => uint256) private tokenOf;
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
    function privateMint(bytes32[] calldata factionProof) public payable nonReentrant {
        require(msg.value == mintPrice, 'WRONG VALUE');
        require(mintState == MintState.PRIVATE, 'WRONG MINTSTATE');
        require(verifyMerkle(factionProof, reapersRoot, msg.sender) || verifyMerkle(factionProof, trickstersRoot, msg.sender), "NOT WHITELISTED");
        require(!hasMintedGen[msg.sender][generation], 'ALREADY MINTED');
        require(balanceOf(msg.sender) == 0, 'ALREADY OWNS');

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, 'MAX REACHED');
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        if (verifyMerkle(factionProof, reapersRoot, msg.sender)) {
            attributes[tokenId].faction = 'Reapers';
        } else {
            attributes[tokenId].faction = 'Tricksters';
        }
        
        attributes[tokenId].fusionCount = 1;
        attributes[tokenId].generation = generation;
        tokenOf[msg.sender] = tokenId;
        hasMintedGen[msg.sender][generation] = true;
        emit Mint(msg.sender, tokenId, attributes[tokenId].fusionCount, generation, attributes[tokenId].faction);
    }

    function publicMint() public payable nonReentrant {
        require(msg.value == mintPrice, 'WRONG VALUE');
        require(mintState == MintState.PUBLIC, 'WRONG MINTSTATE');
        require(!hasMintedGen[msg.sender][generation], 'ALREADY MINTED');
        require(balanceOf(msg.sender) == 0, 'ALREADY OWNS');

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, 'MAX REACHED');
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        attributes[tokenId].faction = uint(keccak256(abi.encodePacked(msg.sender))) % 2 == 0 ? 'Reapers' : 'Tricksters';
        attributes[tokenId].fusionCount = 1;
        attributes[tokenId].generation = generation;
        tokenOf[msg.sender] = tokenId;
        hasMintedGen[msg.sender][generation] = true;
        emit Mint(msg.sender, tokenId, attributes[tokenId].fusionCount, generation, attributes[tokenId].faction);
    }

    /** 
     * @dev Relies on manually changing _owners & _balances variables from private to internal in ERC-721.sol
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(ERC721.ownerOf(tokenId) == from, 'NOT OWNER');
        require(to != address(0), 'ILLEGAL TRANSFER');
        require(from != to, 'ILLEGAL TRANSFER');

        if (balanceOf(to) == 0) {
            _beforeTokenTransfer(from, to, tokenId);

            _approve(address(0), tokenId);

            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;
            tokenOf[to] = tokenId;

            _afterTokenTransfer(from, to, tokenId);
        } else {
            _burn(tokenId);

            attributes[tokenOf[to]].fusionCount += attributes[tokenId].fusionCount;

            if (attributes[tokenId].generation < attributes[tokenOf[to]].generation) {
                attributes[tokenOf[to]].generation = attributes[tokenId].generation;
            }

            emit Fusion(tokenOf[to], attributes[tokenOf[to]].fusionCount);   
        }

        delete tokenOf[from];
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
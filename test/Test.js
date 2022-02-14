const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const createMerkleTree = require("../utils/createMerkleTree");
const keccak256 = require("keccak256");

describe("OnChain", async () => {
  let contractFactory, contract;

  let {
    rootHash: reapersRootHash,
    leafNodes: reapersLeafNodes,
    merkleTree: reapersMerkleTree,
  } = createMerkleTree();

  let {
    rootHash: trickstersRootHash,
    leafNodes: trickstersLeafNodes,
    merkleTree: trickstersMerkleTree,
  } = createMerkleTree();

  console.log(
    reapersMerkleTree.getHexProof(
      keccak256("0x3ada73b8bff6870071ac47484d10520cd41f2c23")
    )
  );

  console.log(`Reapers Root Hash is: ${reapersRootHash}`);
  console.log(`Tricksters Root Hash is: ${trickstersRootHash}`);

  describe("Deploy", () => {
    it("Should deploy.", async function () {
      contractFactory = await ethers.getContractFactory("OnChain");
      contract = await contractFactory.deploy();
      await contract.deployed();
      console.log(`Contract address is: ${contract.address}`);
    });
  });

  describe("MerkleTree", () => {
    it("Should create and verify Merkle Tree.", async function () {
      assert.equal(
        reapersMerkleTree.verify(
          reapersMerkleTree.getHexProof(reapersLeafNodes[0]),
          reapersLeafNodes[0],
          reapersRootHash
        ),
        true
      );
      assert.equal(
        trickstersMerkleTree.verify(
          trickstersMerkleTree.getHexProof(trickstersLeafNodes[0]),
          trickstersLeafNodes[0],
          trickstersRootHash
        ),
        true
      );
    });
  });

  describe("sendRootHash", () => {
    it("Should send rootHash.", async function () {
      await contract.setRootHashes(reapersRootHash, trickstersRootHash);
    });
  });

  describe("changeMintState", () => {
    it("Should change mint state.", async function () {
      await contract.changeMintState(1);
    });
  });

  describe("Mint", () => {
    it("Should mint.", async function () {
      const [owner, second, third, fourth] = await hre.ethers.getSigners();

      const tx = await contract.safeMint(
        reapersMerkleTree.getHexProof(
          keccak256(
            hre.network.config.chainId == 31337
              ? owner.address
              : "0x3ada73b8bff6870071ac47484d10520cd41f2c23"
          )
        )
      );

      const uri = await contract.tokenURI(0);
      console.log(uri);
    });
  });
});

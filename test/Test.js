const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const createMerkleTree = require("../utils/createMerkleTree");
const keccak256 = require("keccak256");

describe("OnChain", async () => {
  let rendererContractFactory,
    rendererContract,
    collectionContractFactory,
    collectionContract;

  let { rootHash, leafNodes, merkleTree } = createMerkleTree();

  describe("Deploy", () => {
    it("Should deplyoy", async function () {
      rendererContractFactory = await ethers.getContractFactory("Renderer");
      rendererContract = await rendererContractFactory.deploy();
      await rendererContract.deployed();

      collectionContractFactory = await ethers.getContractFactory("OnChain");
      collectionContract = await collectionContractFactory.deploy();
      await collectionContract.deployed();
    });
  });

  describe("SetRenderer", () => {
    it("Should set renderer address.", async function () {
      const tx = await collectionContract.setRenderer(rendererContract.address);
      await tx.wait();
    });
  });

  describe("MerkleTree", () => {
    it("Should create and verify Merkle Tree.", async function () {
      assert.equal(
        merkleTree.verify(
          merkleTree.getHexProof(leafNodes[0]),
          leafNodes[0],
          rootHash
        ),
        true
      );
    });
  });

  describe("sendRootHash", () => {
    it("Should send rootHash.", async function () {
      const tx = await collectionContract.setRootHash(rootHash);
      await tx.wait();
    });
  });

  describe("changeMintState", () => {
    it("Should change mint state.", async function () {
      const tx = await collectionContract.changeMintState(1);
      await tx.wait();
    });
  });

  describe("Mint", () => {
    it("Should mint.", async function () {
      const [owner, second, third, fourth] = await hre.ethers.getSigners();

      const tx = await collectionContract.safeMint(
        merkleTree.getHexProof(keccak256(owner.address))
      );
      await tx.wait();
    });
  });
});

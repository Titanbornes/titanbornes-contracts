const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const createMerkleTree = require("../utils/createMerkleTree");

describe("OnChain", async () => {
  let rootHash,
    rendererContractFactory,
    rendererContract,
    collectionContractFactory,
    collectionContract;

  let { leaves, merkleTree } = createMerkleTree();
  console.log(merkleTree);

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
      const proof = merkleTree.getHexProof(leaves[0]);
      rootHash = merkleTree.getHexRoot();

      assert.equal(merkleTree.verify(proof, leaves[0], rootHash), true);
    });
  });

  describe("sendRootHash", () => {
    it("Should send rootHash.", async function () {
      const tx = await collectionContract.setRootHash(
        ethers.utils.formatBytes32String(rootHash)
      );
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

      console.log(`Owner is: ${owner.address}`);

      const proof = merkleTree.getHexProof(leaves[0]);

      console.log(`Proof is: ${proof}`);

      const tx = await collectionContract.safeMint(proof);
      await tx.wait();
    });
  });
});

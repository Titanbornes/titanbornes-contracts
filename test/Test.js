const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const createMerkleTree = require("../utils/createMerkleTree");
const keccak256 = require("keccak256");
const colors = require("colors");

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

  console.log(`Reapers Root Hash is: ${reapersRootHash}`.blue);
  console.log(`Tricksters Root Hash is: ${trickstersRootHash}`.blue);

  describe("Deploy", () => {
    it("Should deploy.", async function () {
      contractFactory = await ethers.getContractFactory("OnChain");
      contract = await contractFactory.deploy();
      await contract.deployed();

      // console.log(`Contract address is: ${contract.address}`.blue);
    });
  });

  describe("changeMintState", () => {
    it("Should change mint state.", async function () {
      await contract.changeMintState(1);

      assert.equal(await contract.mintState(), 1);
    });
  });

  describe("setEndpoint", () => {
    it("Should change endpoint.", async function () {
      await contract.setEndpoint(
        "https://titanbornes.herokuapp.com/api/tokenURI/"
      );

      assert.equal(
        await contract.endpoint(),
        "https://titanbornes.herokuapp.com/api/tokenURI/"
      );
    });
  });

  describe("setPrice", () => {
    it("Should change price.", async function () {
      await contract.setPrice(0);

      assert.equal(await contract.mintPrice(), 0);
    });
  });

  describe("flipBerserk", () => {
    it("Should flip berserk.", async function () {
      await contract.flipBerserk();

      assert.equal(await contract.berserk(), false);
    });
  });

  describe("modifyGen", () => {
    it("Should modify generation.", async function () {
      await contract.modifyGen(15);

      assert.equal(await contract.generation(), 15);
    });
  });

  describe("setMaxSupply", () => {
    it("Should modify maxSupply.", async function () {
      await contract.setMaxSupply(15000);

      assert.equal(await contract.maxSupply(), 15000);
    });
  });

  describe("setStakingAddresses", () => {
    it("Should set a staking address.", async function () {
      await contract.setStakingAddresses(
        "0xf57b2c51ded3a29e6891aba85459d600256cf317"
      );

      assert.equal(
        await contract.stakingAddresses(
          "0xf57b2c51ded3a29e6891aba85459d600256cf317"
        ),
        true
      );
    });
  });

  describe("setProxies", () => {
    it("Should flip proxy state.", async function () {
      await contract.setProxies("0xf57b2c51ded3a29e6891aba85459d600256cf317");

      assert.equal(
        await contract.approvedProxies(
          "0xf57b2c51ded3a29e6891aba85459d600256cf317"
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

  describe("Mint", () => {
    it("Should mint.", async function () {
      const [owner, second, third, fourth] = await hre.ethers.getSigners();

      await contract.safeMint(
        reapersMerkleTree.getHexProof(
          keccak256(
            hre.network.config.chainId == 31337
              ? owner.address
              : "0x3ada73b8bff6870071ac47484d10520cd41f2c23"
          )
        )
      );

      // console.log(`tokenURI: ${await contract.tokenURI(0)}`.yellow);
    });
  });

  describe("characterize", () => {
    it("Should change name and description attributes.", async function () {
      await contract.characterize(
        true,
        [0],
        ["Warhammmer"],
        ["This is the Warhammer Titanborne."]
      );

      assert.equal(await contract.characterized(), true);
      // console.log(`${await contract.attributes(0)}`.blue);
    });
  });
});

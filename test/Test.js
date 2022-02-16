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

      console.log(`Contract address is: ${contract.address}`.blue);
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
      await contract.setPrice(await ethers.utils.parseEther("1"));
    });
  });

  describe("flipBerserk", () => {
    it("Should flip berserk.", async function () {
      await contract.flipBerserk();

      assert.equal(await contract.berserk(), true);
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
      const [owner, second, third, fourth, fifth, sixth, seventh] =
        await hre.ethers.getSigners();

      const signers = [owner, second, third];

      if (hre.network.config.chainId == 31337) {
        for (const signer of signers) {
          await contract
            .connect(signer)
            .safeMint(
              reapersMerkleTree.getHexProof(keccak256(signer.address)),
              {
                value: ethers.utils.parseEther("1"),
              }
            );
        }
      } else {
        await contract.safeMint(
          reapersMerkleTree.getHexProof(
            keccak256("0x3ada73b8bff6870071ac47484d10520cd41f2c23")
          )
        );
      }

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

  describe("safeTransferFrom", () => {
    it("Should safely transfer.", async function () {
      const [owner, second, third, fourth, fifth, sixth, seventh] =
        await hre.ethers.getSigners();

      assert.equal(await contract.ownerOf(1), second.address);
      assert.equal(await contract.balanceOf(owner.address), 1);
      assert.equal(await contract.balanceOf(second.address), 1);

      await contract
        .connect(second)
        ["safeTransferFrom(address,address,uint256)"](
          second.address,
          owner.address,
          1
        );

      assert.equal(await contract.balanceOf(owner.address), 1);
      assert.equal(await contract.balanceOf(second.address), 0);
    });
  });

  describe("modifyGen", () => {
    it("Should modify generation.", async function () {
      await contract.modifyGen(1);

      assert.equal(await contract.generation(), 1);
    });
  });

  describe("MintSec", () => {
    it("Should mint.", async function () {
      const [owner, second, third, fourth, fifth, sixth, seventh] =
        await hre.ethers.getSigners();

      const signers = [fourth, fifth];

      if (hre.network.config.chainId == 31337) {
        for (const signer of signers) {
          await contract
            .connect(signer)
            .safeMint(
              reapersMerkleTree.getHexProof(keccak256(signer.address)),
              {
                value: ethers.utils.parseEther("1"),
              }
            );
        }
      }
      // console.log(`tokenURI: ${await contract.tokenURI(0)}`.yellow);
    });

    describe("safeTransferFromSec", () => {
      it("Should safely transfer.", async function () {
        const [owner, second, third, fourth, fifth, sixth, seventh] =
          await hre.ethers.getSigners();

        assert.equal(await contract.tokensOwners(fourth.address, 0), 3);
        assert.equal(await contract.ownerOf(3), fourth.address);
        assert.equal(await contract.balanceOf(fourth.address), 1);
        assert.equal(await contract.balanceOf(owner.address), 1);

        await contract
          .connect(fourth)
          ["safeTransferFrom(address,address,uint256)"](
            fourth.address,
            owner.address,
            3
          );

        assert.equal(await contract.tokensOwners(fourth.address, 0), 0);
        assert.equal(await contract.balanceOf(owner.address), 1);
        assert.equal(await contract.balanceOf(fourth.address), 0);
      });
    });

    describe("Withdraw", () => {
      it("Should deploy.", async function () {
        const [owner, second, third, fourth, fifth, sixth, seventh] =
          await hre.ethers.getSigners();

        const provider = ethers.provider;

        console.log(
          `Before withdraw: ${await provider.getBalance(contract.address)}`.red
            .inverse
        );

        await contract.withdraw();

        console.log(
          `After withdraw: ${await provider.getBalance(contract.address)}`.red
            .inverse
        );
      });
    });
  });
});

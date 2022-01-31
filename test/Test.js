const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OnChain", async () => {
  let rendererContractFactory,
    rendererContract,
    collectionContractFactory,
    collectionContract;

  beforeEach(async () => {
    rendererContractFactory = await ethers.getContractFactory("Renderer");
    rendererContract = await rendererContractFactory.deploy();
    await rendererContract.deployed();

    collectionContractFactory = await ethers.getContractFactory("OnChain");
    collectionContract = await collectionContractFactory.deploy();
    await collectionContract.deployed();
  });

  describe("SetRenderer", () => {
    it("Should set renderer address.", async function () {
      const tx = await collectionContract.setRenderer(rendererContract.address);
      await tx.wait();
    });
  });

  describe("Mint", () => {
    it("Should mint.", async function () {
      const tx = await collectionContract.safeMint();
      await tx.wait();
    });
  });

  //   describe("PushWhitelistedWallets", () => {
  //     it("Should push.", async function () {
  //       const publicArray = require("../export/public.json");
  //       const tx = await collectionContract.modifyEarlyAccessList(publicArray);
  //       await tx.wait();
  //     });
  //   });
});

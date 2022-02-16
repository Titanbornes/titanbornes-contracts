const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("OnChain");
  const contract = await Contract.deploy();

  await contract.deployed();

  console.log("Contract deployed to:", contract.address);

  const network = await ethers.provider.getNetwork();
  const networkName = network.name == "unknown" ? "localhost" : network.name;

  console.log(`Network: ${networkName} (chainId=${network.chainId})`);

  if (networkName != "localhost") {
    console.log("");
    console.log("To verify this contract on Etherscan, try:");
    console.log(
      `npx hardhat verify --network ${networkName} ${contract.address}`
    );
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

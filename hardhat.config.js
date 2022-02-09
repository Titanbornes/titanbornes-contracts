require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {},
    rinkeby: {
      url: process.env.INFURA_RINKEBY_ENDPOINT,
      accounts: [process.env.PRIVATE_KEY],
    },
    ethereum: {
      url: process.env.INFURA_MAINNET_ENDPOINT,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  gasReporter: {
    enabled: true,
    coinmarketcap: process.env.CMC,
    currency: "ETH",
  },
};

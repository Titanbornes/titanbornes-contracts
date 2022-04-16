# titanbornes-contracts

![Titanbornes_TwitterCover@0,5x](https://user-images.githubusercontent.com/45223699/156891223-35d9ee5f-fd5c-40c1-8e45-9d4ecf9b4b77.png)

## Titanbornes

-   Website: [titanbornes.com](https://titanbornes.com/)
-   Twitter: [@titanbornes](https://twitter.com/titanbornes)
-   Discord: [discord.gg/titanbornes](https://discord.gg/titanbornes)

## Usage

Checkout this repo and install dependencies

```shell
git clone https://github.com/titanbornes/titanbornes-contracts
cd titanbornes-contracts
npm install
```

Create your `.env` file according to the `sample.env` provided file.

```shell
MAINNET_PRIVATE_KEY=
RINKEBY_PRIVATE_KEY=
ALCHEMY_RINKEBY_ENDPOINT=
ALCHEMY_MAINNET_ENDPOINT=
CMC_KEY=
ETHERSCAN_KEY=
```

## Testing

There are exhaustive tests provided in the `Test.js` file. You can run the file using this command:

```shell
npx hardhat test
```

## Deploying

You can deploy this contract to Rinkeby testnet. This requires funding a wallet and registering API keys with [Alchemy](https://docs.alchemy.com/alchemy/introduction/getting-started) and [Etherscan]()

Copy `sample.env` to `.env` and edit in your keys. Then:

```shell
npm run rinkeby
```

You can also use the `verify` scripts to verify the contract on Etherscan.

```
npx hardhat verify --network rinkeby <YOUR_CONTRACT_ADDRESS>
```

Substitute `mainnet` for `rinkeby` to deploy for realsies. good luck!

const ethers = require(`ethers`);
const { MerkleTree } = require("merkletreejs");
const crypto = require("crypto");
const keccak256 = require("keccak256");

function generateWallets() {
  let data = {};

  for (let index = 0; index < 3; index++) {
    let id = crypto.randomBytes(32).toString("hex");
    let privateKey = "0x" + id;
    const wallet = new ethers.Wallet(privateKey);

    const address = wallet.address;
    const faction = `${Math.floor(Math.random() * 3)}`;

    data[address] = faction;
  }

  return data;
}

function hashAddress(address, faction) {
  return ethers.utils.solidityKeccak256(
    ["address", "string"],
    [address, faction]
  );
}

function createLeaves() {
  const wallets = generateWallets();
  console.log(`Wallets are: ${JSON.stringify(wallets)}`);

  return Object.entries(wallets).map((wallet) => hashAddress(...wallet));
}

module.exports = function createMerkleTree() {
  const leaves = createLeaves();

  console.log(`Leaves are: ${leaves}`);

  return {
    leaves,
    merkleTree: new MerkleTree(leaves, ethers.utils.keccak256, {
      sortPairs: true,
    }),
  };
};

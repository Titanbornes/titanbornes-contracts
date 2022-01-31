const ethers = require(`ethers`);
const { MerkleTree } = require("merkletreejs");
const crypto = require("crypto");
const keccak256 = require("keccak256");

function generateWallets() {
  let wallets = ["0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"];

  for (let index = 0; index < 90; index++) {
    let id = crypto.randomBytes(32).toString("hex");
    let privateKey = "0x" + id;
    const wallet = new ethers.Wallet(privateKey);

    wallets.push(wallet.address);
  }

  return wallets;
}

module.exports = function createMerkleTree() {
  const wallets = generateWallets();

  const leafNodes = wallets.map((wallet) => keccak256(wallet));

  const merkleTree = new MerkleTree(leafNodes, keccak256, {
    sortPairs: true,
  });

  const rootHash = merkleTree.getHexRoot();

  return {
    rootHash,
    leafNodes,
    merkleTree,
  };
};

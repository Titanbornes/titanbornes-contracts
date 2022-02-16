const ethers = require(`ethers`);
const { MerkleTree } = require("merkletreejs");
const crypto = require("crypto");
const keccak256 = require("keccak256");

function generateWallets() {
  let wallets = [
    "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "0x3ada73b8bff6870071ac47484d10520cd41f2c23",
    "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
    "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
    "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",
    "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc",
    "0x976ea74026e726554db657fa54763abd0c3a0aa9",
  ];

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

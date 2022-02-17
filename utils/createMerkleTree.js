const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

module.exports = function createMerkleTree(faction) {
  const wallets = require(`../data/${faction}Wallets.json`);

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

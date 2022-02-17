const crypto = require("crypto");
const ethers = require(`ethers`);

module.exports = async function generateWallets(count) {
  let wallets;

  for (let index = 0; index < count; index++) {
    let id = crypto.randomBytes(32).toString("hex");
    let privateKey = "0x" + id;
    const wallet = new ethers.Wallet(privateKey);

    wallets.push(wallet.address);
  }

  return wallets;
};

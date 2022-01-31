const ethers = require(`ethers`)
const crypto = require('crypto')
const fs = require('fs')

const createWallet = () => {
	let publicArray = []

	for (let index = 0; index < 500; index++) {
		let id = crypto.randomBytes(32).toString('hex')
		let privateKey = '0x' + id
		const wallet = new ethers.Wallet(privateKey)
		const address = wallet.address
		publicArray.push( address )
	}
	const publicData = JSON.stringify(publicArray, null, 2)

	const dateObject = new Date()
	const currentTime = dateObject.getTime()

	fs.writeFile(`./export/public` + `.json`, publicData, finished)
}

const finished = (error) => {
	if (error) {
		console.log(error)
		return
	}
}

createWallet()
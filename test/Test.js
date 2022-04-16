const { expect, assert } = require('chai')
const { ethers } = require('hardhat')
const colors = require('colors')
const createMerkleTree = require('../utils/createMerkleTree')
const keccak256 = require('keccak256')

describe('Titanbornes', async () => {
    let titanbornesContractFactory, titanbornesContract

    let {
        rootHash: reapersRootHash,
        leafNodes: reapersLeafNodes,
        merkleTree: reapersMerkleTree,
    } = createMerkleTree('reapers')

    let {
        rootHash: trickstersRootHash,
        leafNodes: trickstersLeafNodes,
        merkleTree: trickstersMerkleTree,
    } = createMerkleTree('tricksters')

    console.log(`Reapers Root Hash is: ${reapersRootHash}`.blue)
    console.log(`Tricksters Root Hash is: ${trickstersRootHash}`.blue)

    describe('DeployTitanbornes', () => {
        it('Should deploy.', async function () {
            titanbornesContractFactory = await ethers.getContractFactory(
                'Titanbornes'
            )
            titanbornesContract = await titanbornesContractFactory.deploy()
            await titanbornesContract.deployed()

            console.log(
                `titanbornesContract address is: ${titanbornesContract.address}`
                    .blue
            )
        })
    })

    describe('setMintState', () => {
        it('Should change mint state.', async function () {
            await titanbornesContract.setMintState(1)

            assert.equal(await titanbornesContract.mintState(), 1)
        })
    })

    describe('setEndpoint', () => {
        it('Should change endpoint.', async function () {
            await titanbornesContract.setEndpoint(
                'https://titanbornes.herokuapp.com/api/tokenURI/'
            )

            assert.equal(
                await titanbornesContract.endpoint(),
                'https://titanbornes.herokuapp.com/api/tokenURI/'
            )
        })
    })

    describe('setPrice', () => {
        it('Should change price.', async function () {
            await titanbornesContract.setPrice(ethers.utils.parseEther('1'))
        })
    })

    describe('setMaxSupply', () => {
        it('Should modify maxSupply.', async function () {
            await titanbornesContract.setMaxSupply(5)

            assert.equal(await titanbornesContract.maxSupply(), 5)
        })
    })

    describe('sendRootHash', () => {
        it('Should send rootHash.', async function () {
            await titanbornesContract.setRootHashes(
                reapersRootHash,
                trickstersRootHash
            )
        })
    })

    describe('Mint', () => {
        it('Should mint.', async function () {
            const [owner, second, third, fourth, fifth, sixth, seventh] =
                await hre.ethers.getSigners()

            const signers = [owner, second, third]

            if (hre.network.config.chainId == 31337) {
                for (const signer of signers) {
                    await titanbornesContract
                        .connect(signer)
                        .mint(
                            reapersMerkleTree.getHexProof(
                                keccak256(signer.address)
                            ),
                            {
                                value: ethers.utils.parseEther('1'),
                            }
                        )
                }
            } else {
                await titanbornesContract.mint(
                    reapersMerkleTree.getHexProof(
                        keccak256('0x3ada73b8bff6870071ac47484d10520cd41f2c23')
                    ),
                    {
                        value: ethers.utils.parseEther('1'),
                    }
                )
            }

            // console.log(`tokenURI: ${await titanbornesContract.tokenURI(0)}`.yellow);
        })
    })

    describe('safeTransferFrom', () => {
        it('Should safely transfer.', async function () {
            const [owner, second, third, fourth, fifth, sixth, seventh] =
                await hre.ethers.getSigners()

            assert.equal(await titanbornesContract.ownerOf(1), second.address)
            assert.equal(await titanbornesContract.balanceOf(owner.address), 1)
            assert.equal(await titanbornesContract.balanceOf(second.address), 1)

            await titanbornesContract
                .connect(second)
                ['safeTransferFrom(address,address,uint256)'](
                    second.address,
                    owner.address,
                    1
                )

            assert.equal(await titanbornesContract.balanceOf(owner.address), 1)
            assert.equal(await titanbornesContract.balanceOf(second.address), 0)
        })
    })

    describe('modifyGen', () => {
        it('Should modify generation.', async function () {
            await titanbornesContract.modifyGen(1)

            assert.equal(await titanbornesContract.generation(), 1)
        })
    })
})

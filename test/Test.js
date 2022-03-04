const { expect, assert } = require('chai')
const { ethers } = require('hardhat')
const colors = require('colors')
const createMerkleTree = require('../utils/createMerkleTree')
const keccak256 = require('keccak256')

describe('Titanbornes', async () => {
    let titanbornesContractFactory,
        titanbornesContract,
        proxyContractFactory,
        proxyContract

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

    console.log(
        reapersMerkleTree.getHexProof(
            keccak256('0x3ada73b8bff6870071ac47484d10520cd41f2c23')
        )
    )

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
            await titanbornesContract.setPrice(
                await ethers.utils.parseEther('1')
            )
        })
    })

    describe('setMaxSupply', () => {
        it('Should modify maxSupply.', async function () {
            await titanbornesContract.setMaxSupply(15000)

            assert.equal(await titanbornesContract.maxSupply(), 15000)
        })
    })

    describe('setStakingAddresses', () => {
        it('Should set a staking address.', async function () {
            await titanbornesContract.setStakingAddresses(
                '0xf57b2c51ded3a29e6891aba85459d600256cf317'
            )

            assert.equal(
                await titanbornesContract.stakingAddresses(
                    '0xf57b2c51ded3a29e6891aba85459d600256cf317'
                ),
                true
            )
        })
    })

    describe('setProxies', () => {
        it('Should flip proxy state.', async function () {
            await titanbornesContract.setProxies(
                '0xf57b2c51ded3a29e6891aba85459d600256cf317'
            )

            assert.equal(
                await titanbornesContract.approvedProxies(
                    '0xf57b2c51ded3a29e6891aba85459d600256cf317'
                ),
                true
            )
        })
    })

    describe('sendRootHash', () => {
        it('Should send rootHash.', async function () {
            await titanbornesContract.setRootHashes(
                reapersRootHash,
                trickstersRootHash,
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
                        .presaleMint(
                            reapersMerkleTree.getHexProof(
                                keccak256(signer.address)
                            ),
                            {
                                value: ethers.utils.parseEther('1'),
                            }
                        )
                }
            } else {
                await titanbornesContract.presaleMint(
                    reapersMerkleTree.getHexProof(
                        keccak256('0x3ada73b8bff6870071ac47484d10520cd41f2c23')
                    )
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

    describe('MintSec', () => {
        it('Should mint.', async function () {
            const [owner, second, third, fourth, fifth, sixth, seventh] =
                await hre.ethers.getSigners()

            const signers = [fourth, fifth]

            if (hre.network.config.chainId == 31337) {
                for (const signer of signers) {
                    await titanbornesContract
                        .connect(signer)
                        .presaleMint(
                            reapersMerkleTree.getHexProof(
                                keccak256(signer.address)
                            ),
                            {
                                value: ethers.utils.parseEther('1'),
                            }
                        )
                }
            }
            // console.log(`tokenURI: ${await titanbornesContract.tokenURI(0)}`.yellow);
        })

        describe('safeTransferFromSec', () => {
            it('Should safely transfer.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                assert.equal(
                    await titanbornesContract.tokensOwners(fourth.address, 0),
                    3
                )
                assert.equal(
                    await titanbornesContract.ownerOf(3),
                    fourth.address
                )
                assert.equal(
                    await titanbornesContract.balanceOf(fourth.address),
                    1
                )
                assert.equal(
                    await titanbornesContract.balanceOf(owner.address),
                    1
                )

                await titanbornesContract
                    .connect(fourth)
                    ['safeTransferFrom(address,address,uint256)'](
                        fourth.address,
                        owner.address,
                        3
                    )

                assert.equal(
                    await titanbornesContract.tokensOwners(fourth.address, 0),
                    0
                )
                assert.equal(
                    await titanbornesContract.balanceOf(owner.address),
                    1
                )
                assert.equal(
                    await titanbornesContract.balanceOf(fourth.address),
                    0
                )
            })
        })

        describe('Withdraw', () => {
            it('Should withdraw.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                const provider = ethers.provider

                assert.isAbove(
                    await provider.getBalance(titanbornesContract.address),
                    0
                )

                await titanbornesContract.withdraw()

                assert.equal(
                    await provider.getBalance(titanbornesContract.address),
                    0
                )
            })
        })

        describe('DeployProxy', () => {
            it('Should deploy proxy contract.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                proxyContractFactory = await ethers.getContractFactory('Proxy')
                proxyContract = await proxyContractFactory.deploy()
                await proxyContract.deployed()

                console.log(
                    `proxyContract address is: ${proxyContract.address}`.blue
                )
            })
        })

        describe('SetTitanbornesAddress', () => {
            it('Should set titanbornes address in proxy.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                await proxyContract.setTitanbornesAddress(
                    titanbornesContract.address
                )

                assert.equal(
                    await proxyContract.titanbornesAddress(),
                    titanbornesContract.address
                )
            })
        })

        describe('SetProxyAddress', () => {
            it('Should set proxy address in titanbornes.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                await titanbornesContract.setProxies(proxyContract.address)

                assert.equal(
                    await titanbornesContract.approvedProxies(
                        proxyContract.address
                    ),
                    true
                )
            })
        })

        describe('flipFuse', () => {
            it('Should flip fuse.', async function () {
                await titanbornesContract.flipFuse()

                assert.equal(await titanbornesContract.fuse(), false)
            })
        })

        describe('CallIncreaseFusionCount', () => {
            it('Should call increaseFusionCount in original contract.', async function () {
                const [owner, second, third, fourth, fifth, sixth, seventh] =
                    await hre.ethers.getSigners()

                await proxyContract.incrementFusionCount(0)
            })
        })
    })
})

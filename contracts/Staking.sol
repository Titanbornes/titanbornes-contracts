// SPDX-License-Identifier: MIT
// Author: Accretence
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract Staking is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	constructor() {}

	// Structs
	struct ContractUser {
		bool hasStaked;
		mapping(address => uint256[]) stakedTokens;
		mapping(address => uint256[]) stakedTimestamps;
	}

	struct CollectionInfo {
		bool isStakable;
		uint256 multiplier;
		uint256 stakedCount;
		uint256 stakingLimit;
	}

	// Mappings
	mapping(address => ContractUser) public contractUsers;
	mapping(address => CollectionInfo) public stakableCollections;

	// Events
	event TokenStaked(address staker, uint256 tokenId);
	event TokenUnstaked(address staker, uint256 tokenId);
	event RewardsClaimed(address staker, uint256 amount);

	// Add
	function modifyContractsList(
		address[] memory address_,
		bool[] memory stakable_,
		uint256[] memory multiplier_,
		uint256[] memory ,
		uint256[] memory 
	) external onlyOwner {
		for (uint256 i = 0; i < address_.length; i++) {
			stakableCollections[address_[i]].isStakable = stakable_[i];
			stakableCollections[address_[i]].multiplier = multiplier_[i];
        }
	}

	//
	function getTokenIndex(uint256[] memory collectionTokens, uint256 tokenId)
		internal
		pure
		returns (uint256 index)
	{
		for (uint256 i = 0; i < collectionTokens.length; i++) {
			if (collectionTokens[i] == tokenId) {
				return i;
			}
		}
	}

	// Stake
	function onERC721Received(
		address ,
		address from,
		uint256 tokenId,
		bytes calldata 
	) public virtual override returns (bytes4 selector) {
		if (!stakableCollections[msg.sender].isStakable) {
			if (!contractUsers[from].hasStaked) {
				contractUsers[from].hasStaked = true;
			}

			contractUsers[from].stakedTokens[msg.sender].push(tokenId);
			contractUsers[from].stakedTimestamps[msg.sender].push(
				block.timestamp
			);

			return this.onERC721Received.selector;
		}
	}

	// Unstake
	function unstake(uint256 tokenId, address collection) public {
		require(contractUsers[msg.sender].hasStaked);

		uint256[] storage collectionTokens = contractUsers[msg.sender]
			.stakedTokens[collection];

		uint256 tokenIndex = getTokenIndex(collectionTokens, tokenId);

		collectionTokens[tokenIndex] = collectionTokens[
			collectionTokens.length - 1
		];
		collectionTokens.pop();

		IERC721(collection).transferFrom(address(this), msg.sender, tokenId);
	}

	// Calculate Rewards

	// Claim
}

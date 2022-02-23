// SPDX-License-Identifier: MIT
// Author: @Accretence
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface iTitanbornes {
   function incrementFusionCount(uint256 tokenId) external;
}

contract Proxy is Ownable {
   address public titanbornesAddress;

   function setTitanbornesAddress(address value) external onlyOwner {
      titanbornesAddress = value;
   }

   function incrementFusionCount(uint256 tokenId) external {
        iTitanbornes fetched = iTitanbornes(titanbornesAddress);
        fetched.incrementFusionCount(tokenId);
   }
}
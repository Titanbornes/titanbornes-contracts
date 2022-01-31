// SPDX-License-Identifier: MIT
// Author: Accretence
pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "./interfaces/metadata.sol";

contract Renderer {
    constructor() {}
    
    function tokenURI(uint256 tokenId_, metadataTypes.metadataStruct memory metadata_) external pure returns (string memory) {        
        string[2] memory factions = ["Demon", "Demon Hunter"];

        string memory _attributeNamePrefix = "On-Chain NFT #";
        string memory _attributeDescription = "On-Chain Storytelling Experiment.";
        string memory _attributeTraits = string(abi.encodePacked('"attributes": [{"trait_type": "Fusion Count","value": ', toString(metadata_.fusionCount),'},{"trait_type": "Faction","value": "', factions[metadata_.faction],'"}]'));
        string memory beginning = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1000 1000"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="lightsalmon"/>'));
        string memory middle = "";
        string memory end = '</svg>';

        for(uint256 i = 0; i < metadata_.fusionCount; i++) {
            uint256 size = 150 + (50 * i);
            string memory rect = string(abi.encodePacked('<rect x="50" y="50" dominant-baseline="middle" height="', toString(size), '" width="', toString(size), '" fill="none" stroke="white" stroke-width="5"><animate attributeName="rx" values="0;75;0" dur="5s" repeatCount="indefinite" /></rect>'));
            middle = string(abi.encodePacked(middle, rect));
        }

        string memory output = string(abi.encodePacked(beginning, middle, end));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', _attributeNamePrefix, toString(tokenId_), '", "description": "', _attributeDescription, '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",', _attributeTraits,' }'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * Inspired by OraclizeAPI's implementation - MIT license
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Avatars {
    enum Rarity {
        Common,
        Uncommon,
        Rare,
        Epic,
        Legendary
    }

    struct Avatar {
        string avatarType;
        Rarity rarity;
        uint16 durability;
    }

    Avatar[] public avatars;

    string[10] public avatarTypesPool = [
        "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
        "Shaman", "Mage", "Warlock", "Druid", "Death Knight"
    ];

    mapping(uint256 => address) public avatarToOwner;
    mapping(address => uint256) public ownerAvatarCount;

    event Minted(address indexed to, uint256 tokenId);

    function mintRandomAvatarFromBox(string memory boxType) public returns (uint256) {
        Rarity randomRarity = _getRarityFromBox(boxType);
        string memory randomAvatarType = _getRandomAvatarTypeFromPool();

        Avatar memory newAvatar = Avatar({
            avatarType: randomAvatarType,
            rarity: randomRarity,
            durability: 100
        });

        avatars.push(newAvatar);
        uint256 newAvatarId = avatars.length - 1;

        avatarToOwner[newAvatarId] = msg.sender;
        ownerAvatarCount[msg.sender]++;
        
        emit Minted(msg.sender, newAvatarId);
        return newAvatarId;
    }

    function _getRandomAvatarTypeFromPool() private view returns (string memory) {
       uint256 randomValue = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));

        uint256 index = randomValue % 10; // Since there are 10 possible avatar types
        return avatarTypesPool[index];
    }

    function _getRarityFromBox(string memory boxType) private view returns (Rarity) {
       uint256 randomValue = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, block.coinbase)));
        uint256 weightedRandom = randomValue % 100;

        if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Bronze Box"))) {
            if (weightedRandom < 60) return Rarity.Common;
            if (weightedRandom < 85) return Rarity.Uncommon;
            if (weightedRandom < 95) return Rarity.Rare;
            if (weightedRandom < 99) return Rarity.Epic;
            return Rarity.Legendary;
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Silver Box"))) {
            if (weightedRandom < 40) return Rarity.Common;
            if (weightedRandom < 70) return Rarity.Uncommon;
            if (weightedRandom < 90) return Rarity.Rare;
            if (weightedRandom < 98) return Rarity.Epic;
            return Rarity.Legendary;
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Gold Box"))) {
            if (weightedRandom < 20) return Rarity.Common;
            if (weightedRandom < 40) return Rarity.Uncommon;
            if (weightedRandom < 60) return Rarity.Rare;
            if (weightedRandom < 85) return Rarity.Epic;
            return Rarity.Legendary;
        } else {
            revert("Invalid box type provided.");
        }
    }
}

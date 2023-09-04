// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Avatars is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
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
    address public boxSalesAddress;
    modifier onlyBoxSales() {
    require(msg.sender == boxSalesAddress, "Only BoxSales contract can call this");
    _;
}

function getRarityString(Rarity rarity) public pure returns (string memory) {
    if (rarity == Rarity.Common) {
        return "Common";
    } else if (rarity == Rarity.Uncommon) {
        return "Uncommon";
    } else if (rarity == Rarity.Rare) {
        return "Rare";
    } else if (rarity == Rarity.Epic) {
        return "Epic";
    } else if (rarity == Rarity.Legendary) {
        return "Legendary";
    } else {
        revert("Invalid rarity");
    }
}

function setBoxSalesAddress(address _boxSalesAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    boxSalesAddress = _boxSalesAddress;
}

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string[10] public avatarTypesPool = [
        "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
        "Shaman", "Mage", "Warlock", "Druid", "Knight"
    ];

    event Minted(address indexed to, uint256 tokenId);

    constructor() ERC721("AvatarsNFT", "AVT") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
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

  function mintRandomAvatarFromBox(address to, string memory boxType) public onlyBoxSales returns (uint256 avatarId, string memory avatarType, string memory rarity, uint16 durability) {
        Rarity randomRarity = _getRarityFromBox(boxType);
        string memory randomAvatarType = _getRandomAvatarTypeFromPool();
        
        if (randomRarity == Rarity.Common) {
            durability = 100;
        } else if (randomRarity == Rarity.Uncommon) {
            durability = 200;
        } else if (randomRarity == Rarity.Rare) {
            durability = 300;
        } else if (randomRarity == Rarity.Epic) {
            durability = 400;
        } else {
            durability = 500;
        }

        Avatar memory newAvatar = Avatar({
            avatarType: randomAvatarType,
            rarity: randomRarity,
            durability: durability
        });

        avatars.push(newAvatar);
        uint256 newAvatarId = avatars.length - 1;

        _mint(to, newAvatarId);
        
        emit Minted(to, newAvatarId);
    return (newAvatarId, randomAvatarType, getRarityString(randomRarity), durability);
    }

struct AvatarDetails {
    uint256 id;
    string avatarType;
    string rarity;
    uint16 durability;
}

function getAvatarsByOwner(address owner) external view returns (AvatarDetails[] memory) {
    uint256 tokenCount = balanceOf(owner);

    AvatarDetails[] memory avatarDetailsArray = new AvatarDetails[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
        uint256 tokenId = tokenOfOwnerByIndex(owner, i);
        Avatar memory avatar = avatars[tokenId];
        avatarDetailsArray[i] = AvatarDetails({
            id: tokenId,
            avatarType: avatar.avatarType,
            rarity: getRarityString(avatar.rarity),
            durability: avatar.durability
        });
    }
    return avatarDetailsArray;
}

    function _baseURI() internal pure override returns (string memory) {
        return "https://leagueofcryptowars.com";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function increaseDurability(uint256 tokenId, uint16 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    avatars[tokenId].durability += amount;
}


function decreaseDurability(uint256 tokenId, uint16 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(avatars[tokenId].durability >= amount, "Durability cannot be negative");

    avatars[tokenId].durability -= amount;

    if (avatars[tokenId].durability <= 0) {
        _burn(tokenId);
    }
}

function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    delete avatars[tokenId];
    super._burn(tokenId);
}

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


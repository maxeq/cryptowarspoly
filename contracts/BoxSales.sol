// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./GameToken.sol";
import "./Avatars.sol";

contract BoxSales is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    GameToken public gameToken;
    Avatars public avatars;

    address public owner;

    enum BoxType { Bronze, Silver, Gold }
    mapping(BoxType => uint256) public boxPriceInWei;
    mapping(BoxType => uint256) public tokensRewarded;

    event BoxPurchased(address indexed user, BoxType boxType);
    event BoxUnboxed(address indexed user, uint256 avatarId, uint256 tokenAmount);

    constructor(address _gameToken, address _avatars) ERC721("BoxNFT", "BOX") {
        gameToken = GameToken(_gameToken);
        avatars = Avatars(_avatars);
        owner = msg.sender;

        boxPriceInWei[BoxType.Bronze] = 0.01 ether;
        boxPriceInWei[BoxType.Silver] = 0.05 ether; 
        boxPriceInWei[BoxType.Gold] = 0.1 ether;

        tokensRewarded[BoxType.Bronze] = 10;
        tokensRewarded[BoxType.Silver] = 50; 
        tokensRewarded[BoxType.Gold] = 100; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function buyBox(BoxType _boxType) public payable {
        require(msg.value == boxPriceInWei[_boxType], "Incorrect Ether sent");

        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        emit BoxPurchased(msg.sender, _boxType);
    }

    function unbox() public {
        uint256 tokenId = _tokenIdOfBoxOwnedBy(msg.sender);
        _burn(tokenId);

        BoxType ownedBox = BoxType(tokenId % 3); // Simple way to determine box type from tokenId

        string memory boxName = _getBoxName(ownedBox);
        uint256 avatarId = avatars.mintRandomAvatarFromBox(boxName);

        uint256 tokenReward = tokensRewarded[ownedBox];
        gameToken.mint(msg.sender, tokenReward);

        emit BoxUnboxed(msg.sender, avatarId, tokenReward);
    }

    function setBoxPrice(BoxType _boxType, uint256 _priceInWei) external onlyOwner {
        boxPriceInWei[_boxType] = _priceInWei;
    }

    function setTokenReward(BoxType _boxType, uint256 _tokenReward) external onlyOwner {
        tokensRewarded[_boxType] = _tokenReward;
    }

    function _getBoxName(BoxType _boxType) private pure returns (string memory) {
        if (_boxType == BoxType.Bronze) return "Bronze Box";
        if (_boxType == BoxType.Silver) return "Silver Box";
        return "Gold Box";
    }

    function _tokenIdOfBoxOwnedBy(address user) private view returns (uint256) {
        return tokenOfOwnerByIndex(user, 0); // Assuming each user owns only one box at a time
    }
}

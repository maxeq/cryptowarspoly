// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./GameToken.sol";
import "./Avatars.sol";

contract BoxSales {
    GameToken public gameToken;
    Avatars public avatars;

    address public owner;

    enum BoxType { Bronze, Silver, Gold }
    mapping(BoxType => uint256) public boxPriceInWei;  // Set box prices in Wei
    mapping(BoxType => uint256) public tokensRewarded; // Set tokens rewarded for buying a box

    event BoxPurchased(address indexed user, BoxType boxType, uint256 avatarId, uint256 tokenAmount);

    constructor(address _gameToken, address _avatars) {
        gameToken = GameToken(_gameToken);
        avatars = Avatars(_avatars);
        owner = msg.sender;

        // Initial pricing and rewards
        boxPriceInWei[BoxType.Bronze] = 0.01 ether; // just an example
        boxPriceInWei[BoxType.Silver] = 0.05 ether; 
        boxPriceInWei[BoxType.Gold] = 0.1 ether;

        tokensRewarded[BoxType.Bronze] = 10; // example token rewards
        tokensRewarded[BoxType.Silver] = 50; 
        tokensRewarded[BoxType.Gold] = 100; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function buyBox(BoxType _boxType) public payable {
        require(msg.value == boxPriceInWei[_boxType], "Incorrect Ether sent");

        // Reward tokens for purchase
        uint256 tokenReward = tokensRewarded[_boxType];
        gameToken.mint(msg.sender, tokenReward);

        // Mint a new avatar based on box type
        string memory boxName = _getBoxName(_boxType);
        uint256 avatarId = avatars.mintRandomAvatarFromBox(boxName);

        emit BoxPurchased(msg.sender, _boxType, avatarId, tokenReward);
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
}

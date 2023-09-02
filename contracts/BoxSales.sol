// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./GameToken.sol";
import "./Avatars.sol";

contract BoxSales is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    GameToken public gameToken;
    Avatars public avatars;

    enum BoxType { Bronze, Silver, Gold }
    mapping(BoxType => uint256) public boxPriceInWei;
    mapping(BoxType => uint256) public tokensRewarded;
    mapping(BoxType => string) public boxURIs;
    mapping(uint256 => BoxType) private _tokenBoxType;

    event BoxPurchased(address indexed user, BoxType boxType);
    event BoxUnboxed(address indexed user, uint256 avatarId, uint256 tokenAmount, BoxType boxType);

    constructor(address _gameToken, address _avatars) ERC721("BoxNFT", "BOX") {
        gameToken = GameToken(_gameToken);
        avatars = Avatars(_avatars);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        boxPriceInWei[BoxType.Bronze] = 0.01 ether;
        boxPriceInWei[BoxType.Silver] = 0.05 ether; 
        boxPriceInWei[BoxType.Gold] = 0.1 ether;

        tokensRewarded[BoxType.Bronze] = 10;
        tokensRewarded[BoxType.Silver] = 50; 
        tokensRewarded[BoxType.Gold] = 100; 

        // Set default URIs for each box type
        boxURIs[BoxType.Bronze] = "https://leagueofcryptowars.com/metadata/bronze_box.json";
        boxURIs[BoxType.Silver] = "https://leagueofcryptowars.com/metadata/silver_box.json";
        boxURIs[BoxType.Gold] = "https://leagueofcryptowars.com/metadata/gold_box.json";
    }

    function buyBox(BoxType _boxType) public payable {
        require(msg.value == boxPriceInWei[_boxType], "Incorrect Ether sent");

        uint256 newTokenId = _tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, boxURIs[_boxType]);

        // Associate the minted tokenId with its BoxType
        _tokenBoxType[newTokenId] = _boxType;

        _tokenIdCounter.increment();

        emit BoxPurchased(msg.sender, _boxType);
    }

    function unbox(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this box");
        require(_exists(tokenId), "Token ID does not exist");

        BoxType ownedBox = _tokenBoxType[tokenId];
        _burn(tokenId);

        string memory boxName = _boxTypeToString(ownedBox);
        uint256 avatarId = avatars.mintRandomAvatarFromBox(boxName);

        uint256 tokenReward = tokensRewarded[ownedBox];
        gameToken.mint(msg.sender, tokenReward);

        emit BoxUnboxed(msg.sender, avatarId, tokenReward, ownedBox);
    }

    function setBoxPrice(BoxType _boxType, uint256 _priceInWei) external onlyRole(DEFAULT_ADMIN_ROLE) {
        boxPriceInWei[_boxType] = _priceInWei;
    }

    function setTokenReward(BoxType _boxType, uint256 _tokenReward) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokensRewarded[_boxType] = _tokenReward;
    }

    function setBoxURI(BoxType _boxType, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        boxURIs[_boxType] = _uri;
    }

    function _boxTypeToString(BoxType _boxType) internal pure returns (string memory) {
        if (_boxType == BoxType.Bronze) return "Bronze Box";
        if (_boxType == BoxType.Silver) return "Silver Box";
        return "Gold Box";
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

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

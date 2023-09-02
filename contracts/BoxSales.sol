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

    event BoxPurchased(address indexed user, BoxType boxType);
    event BoxUnboxed(address indexed user, uint256 avatarId, uint256 tokenAmount);

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

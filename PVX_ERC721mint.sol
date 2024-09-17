// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PVX_ERC721mint is ERC721Enumerable, Ownable, Pausable  {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;// Base URI for token metadata
    address private _newOwner;

    mapping(uint256 => address) public itemCreators;// Mapping for tracking item creators by token ID
    mapping(uint256 => uint256) public imageIDtoMintCount; // Tracks mint count for each ImageID
    mapping(uint256 => string) public tokenURIs;// Mapping for custom token URIs by token ID
    mapping(address => bool) public marketplaceAddresses;// Mapping to manage who can mint tokens
    mapping(uint256 => uint256) public tokenIDtoImageID;// Mapping to track ImageID per TokenID

    event MarketplaceAddressSet(address indexed marketplace, bool status);
    event TokenMinted(uint256 indexed tokenId, uint256 indexed imageId, address indexed recipient);
    
    // Constructor to initialize the ERC721 token's name and symbol.
    constructor(string memory baseTokenURI)ERC721("PVX_ERC721mint", "PVX") {
        require(bytes(baseTokenURI).length > 0, "PVX_ERC721mint: baseTokenURI is empty");
        _baseTokenURI = baseTokenURI;
        marketplaceAddresses[msg.sender] = true;
    } 

    // Pauses the contract, disabling all token trading functions.
    function pause() public onlyOwner {
        _pause();
    }
    // Unpauses the contract, enabling all token trading functions.
    function unpause() public onlyOwner {
        _unpause();
    }

    // Prevents renouncing ownership to ensure contract functionality.
    function renounceOwnership() public override onlyOwner {
        revert("Ownership cannot be renounced");
    }
    // Proposes a new owner for the contract, to be accepted by the new owner.
    function proposeNewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _newOwner = newOwner;
    }
    // Allows the new owner to accept ownership, completing the transfer process.
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Only proposed new owner can accept ownership");
        _transferOwnership(_newOwner);
        _newOwner = address(0);
    }

    // Overridden function to provide the URI of a token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "URI query for nonexistent token");
        return tokenURIs[tokenId];
    }

    // Allows an owner of a token to burn (destroy) it.
    function burn(uint256 id) external {
        require(msg.sender == ownerOf(id), "You can only burn tokens that you own");
        _burn(id);
    }

    // Function to set or unset an address as a marketplace
    function setMarketplaceAddress(address marketplace, bool status) public onlyOwner {
        marketplaceAddresses[marketplace] = status;
        emit MarketplaceAddressSet(marketplace, status);
    }
    
    // Modifier to restrict function calls to approved marketplace addresses only
    modifier onlyMarketplace() {
        require(marketplaceAddresses[msg.sender], "Caller is not a marketplace");
        _;
    }

    // Mint a single token for a marketplace transaction
    function mintForMarketplace(uint256 imageID, address recipient) external onlyMarketplace whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(_baseTokenURI, Strings.toString(imageID))));
        tokenIDtoImageID[newTokenId] = imageID;
        imageIDtoMintCount[imageID] += 1;

        emit TokenMinted(newTokenId, imageID, recipient);
        return newTokenId;
    }

    // Sets a custom URI for a given token ID
    function _setTokenURI(uint256 tokenId, string memory uri) private {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        tokenURIs[tokenId] = uri;
    }

    // Public mint function for owner
    function mintByOwner(uint256 imageID) external onlyOwner whenNotPaused{
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(_baseTokenURI, Strings.toString(imageID))));
        // Increment the mint count for the ImageID and register the ImageID with the new TokenID
        imageIDtoMintCount[imageID] += 1; 
        tokenIDtoImageID[newTokenId] = imageID; 
    }

   // Returns the list of ImageIDs and TokenIDs owned by a wallet address
    function GetOwnedTokens(address tokenOwner) public view returns (uint256[] memory, uint256[] memory) {
        uint256 tokenCount = balanceOf(tokenOwner);
        uint256[] memory ownedImageIDs = new uint256[](tokenCount);
        uint256[] memory ownedTokenIDs = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenID = tokenOfOwnerByIndex(tokenOwner, i);
            ownedTokenIDs[i] = tokenID;
            ownedImageIDs[i] = tokenIDtoImageID[tokenID];
        }

        return (ownedImageIDs, ownedTokenIDs);
    }

}

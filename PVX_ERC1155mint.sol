// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


contract PVX_ERC1155mint is ERC1155, ERC1155Supply, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    address private _newOwner;

    mapping(uint256 => uint256) public maxMintPerTokenId; // Mapping to store maximum mint amount per token ID
    mapping(uint256 => string) public tokenURIs;// Mapping to store custom URIs for each token ID
    mapping(address => bool) public marketplaceAddresses;// Mapping to store approved marketplace addresses
    mapping(address => EnumerableSet.UintSet) private ownedTokenIds;

    event MarketplaceAddressSet(address indexed marketplace, bool status);
    event MaxMintPerTokenIdSet(uint256 tokenId, uint256 maxMint);
    event TokenURISet(uint256 tokenId, string newURI);
    
    constructor(string memory _baseURI) ERC1155(_baseURI) {
        require(bytes(_baseURI).length > 0, "BaseURI cannot be empty");
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

    // Allows the contract owner to add or remove marketplace addresses
    function setMarketplaceAddress(address marketplace, bool status) public onlyOwner {
        marketplaceAddresses[marketplace] = status;
        emit MarketplaceAddressSet(marketplace, status);
    }

    // Modifier to restrict function calls to approved marketplace addresses only
    modifier onlyMarketplace() {
        require(marketplaceAddresses[msg.sender], "Caller is not the marketplace");
        _;
    }

    // Allows marketplaces to mint tokens on behalf of users
    function mintForMarketplace(uint256[] memory tokenIds, uint256[] memory amounts, address recipient) external onlyMarketplace whenNotPaused {
        require(tokenIds.length == amounts.length, "Mismatch between token IDs and amounts");
        
        for (uint i = 0; i < tokenIds.length; i++) {
            require(maxMintPerTokenId[tokenIds[i]] >= amounts[i] + totalSupply(tokenIds[i]), "Exceeds max mint amount for token");
        }
        _mintBatch(recipient, tokenIds, amounts, "");
    }

    // Sets the maximum mint amount for a specific token ID
    function setMaxMintPerTokenId(uint256 tokenId, uint256 maxMint) public onlyOwner {
        maxMintPerTokenId[tokenId] = maxMint;
        emit MaxMintPerTokenIdSet(tokenId, maxMint);
    }

    // Sets a custom URI for a specific token ID
    function setTokenURI(uint256 tokenId, string memory newURI) public onlyOwner {
        tokenURIs[tokenId] = newURI;
        emit TokenURISet(tokenId, newURI);
    }

    // Allows users to mint tokens
    function mintByOwner(uint256 tokenId, uint256 amount, address to) public onlyOwner whenNotPaused {
        require(totalSupply(tokenId) + amount <= maxMintPerTokenId[tokenId], "Exceeds max mint amount for token");
        _mint(to, tokenId, amount, "");
    }

    // Overrides the default URI function to provide a custom URI for each token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        // Check if a custom URI has been set for the given tokenId
        if (bytes(tokenURIs[tokenId]).length > 0) {
            return tokenURIs[tokenId];
        }
        // If no custom URI is set, return the default URI with the tokenId appended
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
    }

    // Function to burn tokens
    function _burn(address account, uint256 id, uint256 amount) internal override {
        super._burn(account, id, amount);
        
        if (balanceOf(account, id) == 0) {
            ownedTokenIds[account].remove(id);
        }
    }

    // Burn function for specific NFTs by owner
    function burnTokenForUser(uint256 tokenId, uint256 amount, address tokenOwner) public onlyOwner {
        require(balanceOf(tokenOwner, tokenId) >= amount, "User does not own enough tokens");
        _burn(tokenOwner, tokenId, amount);
    }

    // Pauses the contract, disabling all token trading functions.
    function pause() public onlyOwner {
        _pause();
    }
    // Unpauses the contract, enabling all token trading functions.
    function unpause() public onlyOwner {
        _unpause();
    }

    
    // Override the mint function to update the list of owned token IDs
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(account, id, amount, data);
        ownedTokenIds[account].add(id);
    }

    // Override the mintBatch function to update the list of owned token IDs
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            ownedTokenIds[to].add(ids[i]);
        }
    }
    
    // Internal function hook that is called before any token transfer.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                if (balanceOf(from, ids[i]) == amounts[i]) {
                    ownedTokenIds[from].remove(ids[i]);
                }
            }
        }
        
        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                ownedTokenIds[to].add(ids[i]);
            }
        }
    }

    // Function to return all token IDs and their quantities owned by a specified address
    function getAllOwnedTokens(address tokenOwner) public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](ownedTokenIds[tokenOwner].length());
        
        for (uint256 i = 0; i < ownedTokenIds[tokenOwner].length(); ++i) {
            ids[i] = ownedTokenIds[tokenOwner].at(i);
        }
        return ids;
    }

}

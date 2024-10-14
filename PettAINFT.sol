// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./attestable/SignatureAttestable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

struct communitySlot {
	string community;
	uint256 endTime;
	uint256 supply;
}

struct airdopSlot {
	string community;
	address[] addresses;
}

contract PettAINFT is ERC721, ERC721Burnable, Ownable, SignatureAttestable {
	using Strings for uint256;
	using Counters for Counters.Counter;


	Counters.Counter private _supply;

	string private baseURI;

    mapping (address => uint256) public hasMinted;

	mapping (uint256 => string) public tokenCommunity;

	communitySlot[] public communitySlots;
	uint256 private currentMaxSupply = 0;
	uint256 public constant MAX_SUPPLY = 10000;
	address public teamWallet;

	uint256 public mint_time = ~uint256(0); // MAX_UINT256

	constructor(string memory _initBaseURI, address signerAddress, address _teamWallet, airdopSlot memory airdop) ERC721("PettAI NFT", "PAI Egg") SignatureAttestable(signerAddress)  {
		_supply.increment();
		setBaseURI(_initBaseURI);
		teamWallet = _teamWallet;

		// add airdop
		for(uint256 i = 0; i < airdop.addresses.length; i++){
			_safeMint(airdop.addresses[i], _supply.current());
			tokenCommunity[_supply.current()] = airdop.community;
			hasMinted[airdop.addresses[i]] = _supply.current();
			_supply.increment();
		}
	}

	// Get total supply
	function totalSupply() public view returns (uint256) {
		return _supply.current() - 1;
	}
	
	function currentTotalSupply() public view returns (uint256) {
		uint256 i;
		for(i = 0; communitySlots[i].endTime < block.timestamp; i++){}
		return communitySlots[i].supply;
	}

	// Base URI
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function setMintTime(uint256 _mint_time) public onlyOwner {
		require(_mint_time > block.timestamp, "Mint time must be in the future.");
		mint_time = _mint_time;
		// clear community slots
		delete communitySlots;
	}

	function getCommunitySlots() public view returns (communitySlot[] memory) {
		return communitySlots;
	}

	function getCurrentSlot() public view returns (communitySlot memory) {
		if(communitySlots.length == 0){
			return communitySlot("", 0, 0);
		}
		uint256 i;
		for(i = 0; communitySlots[i].endTime < block.timestamp; i++){}
		return communitySlots[i];
	}

	// Set base URI
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setSignerAddress(address _signerAddress) public onlyOwner {
		_setSigner(_signerAddress);
	}

	function addCommunitySlot(string calldata _community, uint256 _endTime, uint256 supply) public onlyOwner {
		if(communitySlots.length == 0 && _endTime < mint_time){
			revert("End time must be greater than the mint time.");
		}
		if(communitySlots.length > 0 && communitySlots[communitySlots.length - 1].endTime >= _endTime){
			revert("End time must be greater than the previous community slot.");
		}
		communitySlots.push(communitySlot(_community, _endTime, supply));
	}

	function addCommunitySlots(communitySlot[] calldata _communitySlots) public onlyOwner {
		for (uint256 i = 0; i < _communitySlots.length; i++) {
			addCommunitySlot(_communitySlots[i].community, _communitySlots[i].endTime, _communitySlots[i].supply);
		}
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseURI(), tokenCommunity[tokenId]));
	}

	// Withdraw balance
	function withdraw() external {
		(bool sent, ) = payable(teamWallet).call{ value: address(this).balance }("");
		require(sent, "Failed to withdraw Ether.");
	}

	// Receive any funds sent to the contract
	receive() external payable {}

	//mint
	function claim(
        bytes calldata signature
    ) external onlyValidSignature(_getHashedData(), signature) {
		address _to = msg.sender;
		require(hasMinted[_to] == 0, "You already have a NFT.");
        require(totalSupply() < MAX_SUPPLY, "Max supply exceeded.");
		
		if (mint_time > block.timestamp){
			revert ClaimNotYetAvailable();
		}
		if(communitySlots.length == 0){
			revert("No community slots available.");
		}
		if (communitySlots[communitySlots.length - 1].endTime < block.timestamp){
			revert("Community slots have ended.");
		}
		uint256 i;
		for(i = 0; communitySlots[i].endTime < block.timestamp; i++){}

		require(communitySlots[i].supply > 0, "Current community slot supply has ended.");

        _safeMint(_to, _supply.current());
		tokenCommunity[_supply.current()] = communitySlots[i].community;
        hasMinted[_to] = _supply.current();
		communitySlots[i].supply--;
		_supply.increment();
    }

    function _getHashedData() internal view returns (bytes32 hashedData) {
        hashedData = keccak256(abi.encode(msg.sender));
    }

    error ClaimNotYetAvailable();
}
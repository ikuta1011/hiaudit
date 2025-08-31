// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PVX_ERC20 is ERC20, ERC20Capped, ERC20Burnable, Ownable {
    address private _newOwner;
    
    constructor(uint256 initialCap) ERC20("PARAVOXToken", "PVX") ERC20Capped(initialCap * (10 ** decimals())) {
        _mint(_msgSender(), 1000000000 * (10 ** decimals()));
    }

    // Overrides the internal _mint function to comply with the cap restriction.
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    // Public mint function that allows only the owner of the contract to mint new tokens.
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
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
}
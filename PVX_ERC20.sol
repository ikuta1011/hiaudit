// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PVX_ERC20 is ERC20, ERC20Capped, ERC20Burnable, Ownable {
    constructor(uint256 cap) ERC20("PARAVOXToken", "PVX") ERC20Capped(cap * (10 ** decimals())) {
        _mint(_msgSender(), 1000000000 * (10 ** decimals()));
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}

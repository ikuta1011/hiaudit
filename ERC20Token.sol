// SPDX-License-Identifier: MIT
pragma solidity  >=0.8.19;

import "./ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol, owner) {
        _mint(owner, initialSupply * 10**uint256(decimals));
    }
}
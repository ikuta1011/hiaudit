// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./ERC20Token.sol";
import "./deps/Ownable.sol";

contract Factory is Ownable {
    event ERC20TokenCreated(address tokenAddress);

    constructor() Ownable(msg.sender) {}

    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply
    ) public returns (address) {
        ERC20Token t = new ERC20Token(
            name,
            symbol,
            decimals,
            initialSupply,
            owner()
        );
        emit ERC20TokenCreated(address(t));

        return address(t);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function faucet() public {
        _mint(msg.sender, 1000 * (10 ** decimals()));
    }
}
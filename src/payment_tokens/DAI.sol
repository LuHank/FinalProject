// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin/token/ERC20/ERC20.sol";

contract DAI is ERC20 {
    constructor() ERC20("DAI", "DAI") {}

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function faucet() public {
        _mint(msg.sender, 1000 * (10 ** decimals()));
    }
}
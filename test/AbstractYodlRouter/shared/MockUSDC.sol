// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Mock USDC contract
contract MockERC20 is ERC20, Ownable {
    uint256 immutable _initial_supply;
    uint256 immutable decimal;

    constructor(string memory _name, string memory _symbol, uint256 _decimals)
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        decimal = _decimals;
        _initial_supply = 10 ** 12 * (10 ** _decimals); // 1e12
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
/**
 * @title Example FID20 Token
 * @dev An example implementation of the FID20 standard for a "memecoin" style token.
 * This contract demonstrates how to use the FID20 standard, highlighting the key
 * differences and additional requirements compared to the ERC20 standard. For more
 * details on FID20, please refer to the comments in FID20.sol in the repository.
 *
 * Requirements / Usage Compared to ERC20:
 * ----------------------------------------
 * - The FID20 instance in the constructor requires an additional parameter compared
 *   to the ERC20 standard. This parameter is the FIDStorage address on HAM L3, which
 *   is necessary to ensure that swaps are only allowed to FID wallets.
 *
 * - The `setAllowlist` function must be overridden in any contracts that inherit
 *   from FID20. This function enables the contract owner to manage an allowlist,
 *   permitting addresses such as routers, pools, and other smart contracts to
 *   interact with your token.
 *
 * - The `_allowlistProxySwap` function is added to allow the contract owner to manage
 *   a list of specific addresses that need to be allowlisted to facilitate trading.
 *   These addresses include key contracts such as the WETH on HAM, Proxyswap Router,
 *   Factory, Position, Quoter, and Fees Contracts. This is essential for enabling
 *   trading functionality.
 *
 * This token serves as an example to help developers learn how to implement and
 * use the FID20 standard.
 */
pragma solidity ^0.8.20;

import {FID20} from "src/FID20/FID20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ExampleFID20Token is FID20, Ownable {
    // FID Contract Address on HAM L3
    address public fidStorageAddress = 0xCca2e3e860079998622868843c9A00dEbb591D30;

    // Example token details
    string private tokenName = "Example FIC20 Token";
    string private tokenTicker = "FID20";
    uint256 public immutable MAX_SUPPLY = 100_000_000 ether;

    constructor() FID20(tokenName, tokenTicker, fidStorageAddress) Ownable(msg.sender) {
        // deployor of the contract is added to the allowlist
        _setAllowlist(msg.sender, true);
        // mint total supply during deployment
        _mint(msg.sender, MAX_SUPPLY);

        // allowlist ProxySwap addresses to enable trading
        _allowlistProxySwap();
    }

    /**
     * @dev Internal function to allowlist specific ProxySwap addresses necessary for trading.
     * This includes WETH on HAM, Proxyswap Router, Factory, Position, Quoter, and Fees Contracts.
     */
    function _allowlistProxySwap() internal {
        _setAllowlist(0x4200000000000000000000000000000000000006, true); // WETH address on Ham L3
        _setAllowlist(0x04f9bf41572550E4F51fD9e595446d235e733C16, true); // Proxyswap Router Contract
        _setAllowlist(0x6bA5888ACa5CfAebdF3c9ace64581c3Aa86e564c, true); // Proxyswap factory Contract
        _setAllowlist(0xD088322Fa988225B3936555894E1D21c1A727859, true); // Proxyswap Position Contract
        _setAllowlist(0xe1ce80a0Ef61867b475048867f59306480e0aE0E, true); // Proxyswap Quoter Contract
        _setAllowlist(0x053707B201385AE3421D450A1FF272952D2D6971, true); // Proxyswap Fees Contract
    }

    /**
     * @dev Function to allow the contract owner to manage the allowlist.
     * This enables the owner to permit addresses that do not have an FID address to interact with the token.
     * @param _address The address to be allowlisted or removed from the allowlist.
     * @param _allowed Boolean indicating whether the address should be allowed or not.
     */
    function setAllowlist(address _address, bool _allowed) public override onlyOwner {
        _setAllowlist(_address, _allowed);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFIDStorage {
    function ownerFid(address owner) external view returns (uint256);
}

contract FIDCoin is ERC20, ERC20Burnable, Ownable {
    /// Custom Errors
    error NoZeroValueTransfers();
    error TokenTransfersOnlyToFIDAccounts();

    uint256 public MAX_SUPPLY = 100000000 ether;
    bool public FIDOnly;
    mapping(address => bool) public FIDWhitelists;

    /// FID Storage
    IFIDStorage public fidStorage;
    address public fidStorageAddress = 0xCca2e3e860079998622868843c9A00dEbb591D30;

    constructor() Ownable(msg.sender) ERC20("FID Only Test Coin", "FIDTEST") {
        _mint(msg.sender, MAX_SUPPLY);
        FIDOnly = true;
        setFIDWhitelist(msg.sender, true);
        fidStorage = IFIDStorage(fidStorageAddress);
    }

    function setFIDOnly(bool _value) external onlyOwner {
        FIDOnly = _value;
    }

    function setFIDWhitelist(address _address, bool _allowed) public onlyOwner {
        FIDWhitelists[_address] = _allowed;
    }

    function getFID(address owner) external view returns (uint256) {
        uint256 fid = fidStorage.ownerFid(owner);
        require(fid != 0, "Address does not have an FID");
        return fid;
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        /// FID Check
        if (FIDOnly) {
            if (!FIDWhitelists[from]) {
                // Check if from address has a non-zero FID
                try this.getFID(from) returns (uint256 fid) {
                    if (fid == 0) {
                        revert TokenTransfersOnlyToFIDAccounts();
                    }
                } catch {
                    revert TokenTransfersOnlyToFIDAccounts();
                }
            }
            if (!FIDWhitelists[to]) {
                // Check if to address has a non-zero FID
                try this.getFID(to) returns (uint256 fid) {
                    if (fid == 0) {
                        revert TokenTransfersOnlyToFIDAccounts();
                    }
                } catch {
                    revert TokenTransfersOnlyToFIDAccounts();
                }
            }
        }

        /// Make sure there is a token balance in the account
        if (value == 0) {
            revert NoZeroValueTransfers();
        }
        // Call the parent contract's _update function
        super._update(from, to, value);
    }
}

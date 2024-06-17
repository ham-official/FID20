// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFIDStorage} from "./interface/IFIDStorage.sol";

contract FIDCoin is ERC20, ERC20Burnable, Ownable {

    /// Custom Errors
    error NoZeroValueTransfers();
    error TokenTransfersOnlyToFIDAccounts(string message, address attemptedAddress);

    /// FID Storage
    IFIDStorage public fidStorage;
    address public fidStorageAddress = 0xCca2e3e860079998622868843c9A00dEbb591D30;
    mapping(address => bool) public Allowlist;

    /// Token Details
    uint256 public immutable MAX_SUPPLY = 1000000 ether;

    constructor() Ownable(msg.sender) ERC20("FID Only Test Coin", "FIDTEST") {
        fidStorage = IFIDStorage(fidStorageAddress);
        setAllowlist(msg.sender, true); // Whitelist the deployer
        setAllowlist(address(0), true); // 0x0 address needs to be on allowlist for mints and burns
        _mint(msg.sender, MAX_SUPPLY);
    }

    function setAllowlist(address _address, bool _allowed) public onlyOwner {
        Allowlist[_address] = _allowed;
    }

   function getFID(address _holder) external view returns (uint256) {
        uint256 fid = fidStorage.ownerFid(_holder);
        require(fid != 0, "Address does not have an FID");
        return fid;
    }

    function _update(address from, address to, uint256 value) internal virtual override {

        bool fromallowlist = Allowlist[from];
        bool toallowlist = Allowlist[to];

        // Check if either from or to is allowlist or has a non-zero FID
        if (!fromallowlist) {
            // Check if from address has a non-zero FID
            try this.getFID(from) returns (uint256 fidFrom) {
                if (fidFrom == 0) {
                    revert TokenTransfersOnlyToFIDAccounts("Transfers can only be made from FID accounts or allowlist addresses", from);
                }
            } catch {
                revert TokenTransfersOnlyToFIDAccounts("Transfers can only be made from FID accounts or allowlist addresses", from);
            }
        }

        if (!toallowlist) {
            // Check if to address has a non-zero FID
            try this.getFID(to) returns (uint256 fidTo) {
                if (fidTo == 0) {
                    revert TokenTransfersOnlyToFIDAccounts("Transfers can only be made to FID addresses or allowlist addresses", to);
                }
            } catch {
                revert TokenTransfersOnlyToFIDAccounts("Transfers can only be made to FID addresses or allowlist addresses", to);
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

// SPDX-License-Identifier: MIT

/**
 * - FID20 - Version v1.0.0 - Developed by Apex777.eth
 *
 * @dev Modified version of OpenZeppelin's ERC20 v5.0.0 to check if an address is
 * associated with a Farcaster account through HAM L3's Onchain Farcaster data.
 *
 * Changes for FID20
 * -----------------
 *
 *  --- Variables ---
 *
 * - Add a new instance of the FIDStorage contract.
 *
 * - Create an allowlist mapping to store addresses that do not have a Farcaster account
 *   but need access to tokens, pools, smart contracts, Uniswap routers, etc.
 *
 * - Custom error for invalid transfers involving addresses not on the allowlist or
 *   not associated with Farcaster accounts.
 *
 *  --- Functions ---
 *
 *  - isFIDWallet    - Public function to check if a wallet is associated with a Farcaster account.
 *
 *  - isAllowlisted  - Public function to check if a wallet is on the allowlist.
 *
 *  - _allowTransfer - Internal function that uses the above functions to check if a transfer should occur.
 *
 *  - _setAllowlist  - Internal function to add wallets to the allowlist mapping.
 *
 *  - setAllowlist   - Abstract function to be implemented by derived contracts to manage the allowlist.
 *                     See method comments for more details.
 *
 */
pragma solidity ^0.8.20;

import {IFID20} from "src/interface/IFID20.sol";
import {IFID20Metadata} from "src/interface/IFID20Metadata.sol";
import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {IFID20Errors} from "src/interface/IFID20Errors.sol";
import {IFIDStorage} from "src/interface/IFIDStorage.sol";

abstract contract FID20 is Context, IFID20, IFID20Metadata, IFID20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// FID Custom Variables
    IFIDStorage private _fidStorage;
    mapping(address => bool) private _allowlist;

    error FID20InvalidTransfer(address attemptedAddress);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, address fidContract_) {
        _name = name_;
        _symbol = symbol_;
        _fidStorage = IFIDStorage(fidContract_);

        // 0x0 address needs to be on allowlist for mints and burns
        _setAllowlist(address(0), true);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     *
     * --- FID20 Custom logic added ---
     *  Hook into _FID20Checks added
     * --- FID20 Custom logic added ---
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        // hook for FID20 custom logic
        _allowTransfer(from, to);

        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }

    /**
     * @dev FID20 custom logic
     *
     *  Public function to check if a wallet is linked to a Farcaster account
     *  ---------------------------------------------------------------------
     *  This function calls the external FIDStorage contract to determine if the
     *  specified wallet address has been linked to a Farcaster account. If an
     *  account is found, a non-zero value is returned.
     *
     *  The function uses a try-catch block to handle potential errors from the
     *  external contract call.
     *
     *  @param wallet The address to check for Farcaster account linkage
     *  @return bool Returns true if the wallet is linked to a Farcaster account, otherwise false
     */
    function isFIDWallet(address wallet) public view returns (bool) {
        try _fidStorage.ownerFid(wallet) returns (uint256 fid) {
            if (fid != 0) {
                return true;
            } else {
                return false;
            }
        } catch {
            return false;
        }
    }

    /**
     * @dev FID20 custom logic
     *
     *  Public function to check Allowlist status
     *  -----------------------------------------
     *  This function checks if a given wallet address has been added to the allowlist.
     *  The allowlist determines if a wallet is permitted to send or receive tokens.
     *
     *  @param wallet The address to check for allowlist status
     *  @return bool Returns true if the wallet is on the allowlist, otherwise false
     */
    function isAllowlisted(address wallet) public view returns (bool) {
        return _allowlist[wallet];
    }

    /**
     * @dev FID20 custom logic
     *
     *  Internal function to manage the Allowlist
     *  -----------------------------------------
     *  This function allows adding or removing addresses from the allowlist,
     *  which determines if a wallet can send or receive tokens.
     *
     *  @param _address The address to be added or removed from the allowlist
     *  @param _allowed Boolean indicating whether the address should be added (true) or removed (false) from the allowlist
     */
    function _setAllowlist(address _address, bool _allowed) internal {
        _allowlist[_address] = _allowed;
    }

    /**
     * @dev FID20 custom logic
     *
     *  Hook called in the standard ERC20 `_update` function
     *  ------------------------------------------------------
     *  Ensures tokens can only be transferred to and from wallets that
     *  are either associated with a Farcaster account or have been added
     *  to the allowlist mapping.
     *
     *  This function performs the following checks:
     *  - Verifies if the `from` address is either on the allowlist or associated with a Farcaster account.
     *  - Verifies if the `to` address is either on the allowlist or associated with a Farcaster account.
     *
     *  If any of these checks fail, the transfer is reverted with a custom error.
     *
     *  @param to The address to which tokens are being transferred
     *  @param from The address from which tokens are being transferred
     */
    function _allowTransfer(address to, address from) internal view {
        bool isFromOnAllowlist = isAllowlisted(from);
        bool isFromFID = isFIDWallet(from);

        bool isToOnAllowlist = isAllowlisted(to);
        bool isToFID = isFIDWallet(to);

        // check from
        if (!isFromOnAllowlist && !isFromFID) {
            revert FID20InvalidTransfer(from);
        }

        // check to
        if (!isToOnAllowlist && !isToFID) {
            revert FID20InvalidTransfer(to);
        }
    }

    /**
     * @dev FID20 custom logic
     *
     *  Abstract function to set wallets on the Allowlist
     *  -------------------------------------------------
     *  Any contract inheriting FID20 must implement this function to allow
     *  adding or removing addresses from the allowlist. This function should
     *  be restricted to the contract owner or an authorized entity.
     *
     *  @param _address The address to be added or removed from the allowlist
     *  @param _allowed Boolean indicating whether the address is allowed or not
     */
    function setAllowlist(address _address, bool _allowed) public virtual;
}

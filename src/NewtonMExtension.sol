// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.27;

import {IERC20} from "../lib/common/src/interfaces/IERC20.sol";
import {MExtension} from "./MExtension.sol";
import {NewtonProtected} from "./proxy/NewtonProtected.sol";

abstract contract NewtonMExtensionStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.NewtonMExtension
    struct NewtonMExtensionStorageStruct {
        uint256 totalSupply;
        mapping(address account => uint256 balance) balanceOf;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.NewtonMExtension")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _NEWTON_M_EXTENSION_STORAGE_LOCATION =
        0x5db7832de89694644441703dce434ce616bfd1332a090f87aa90736d13232149;

    function _getNewtonMExtensionStorageLocation() internal pure returns (NewtonMExtensionStorageStruct storage $) {
        assembly {
            $.slot := _NEWTON_M_EXTENSION_STORAGE_LOCATION
        }
    }
}

/**
 * @title  NewtonMExtension
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token
 *         with Newton Policy protection for transfer, approve, transferFrom, mint, and burn operations.
 * @author M0 Labs
 */
contract NewtonMExtension is NewtonMExtensionStorageLayout, MExtension, NewtonProtected {
    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs NewtonMExtension Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_       The address of $M token.
     * @param  swapFacility_ The address of Swap Facility.
     */
    constructor(address mToken_, address swapFacility_) MExtension(mToken_, swapFacility_) {
        _disableInitializers();
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the Newton M extension token.
     * @param name          The name of the token (e.g. "Newton M Extension").
     * @param symbol        The symbol of the token (e.g. "NME").
     * @param owner         The address of the owner.
     */
    function initialize(string memory name, string memory symbol, address owner) public initializer {
        __MExtension_init(name, symbol);
        if (owner != address(0)) {
            // If NewtonProtected had ownership, we'd set it here
            // For now, we just initialize MExtension
        }
    }

    /* ============ View Functions ============ */

    /// @inheritdoc IERC20
    function balanceOf(address account) public view override returns (uint256) {
        return _getNewtonMExtensionStorageLocation().balanceOf[account];
    }

    /// @inheritdoc IERC20
    function totalSupply() public view override returns (uint256) {
        return _getNewtonMExtensionStorageLocation().totalSupply;
    }

    /* ============ Newton Policy Protected Functions ============ */

    /// @notice Newton Policy Protected function to mint tokens
    function mint(address recipient, uint256 amount) external onlyERC20ProtectedProxy {
        _mint(recipient, amount);
    }

    /// @notice Newton Policy Protected function to burn tokens
    function burn(address account, uint256 amount) external onlyERC20ProtectedProxy {
        _burn(account, amount);
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before approval of M Extension token.
     * @param account   The sender's address.
     * @param spender   The spender address.
     * @param amount    The amount to be approved.
     */
    function _beforeApprove(address account, address spender, uint256 amount) internal view override {
        // Enforce Newton Policy protection when enabled
        if (_getERC20ProtectedProxyEnabled()) {
            if (address(_getERC20ProtectedProxy()) == address(0)) {
                revert ERC20ProtectedProxyNotSet();
            }
            if (msg.sender != address(_getERC20ProtectedProxy())) {
                revert OnlyERC20ProtectedProxy();
            }
        }
    }

    /**
     * @dev   Hook called before transferring M Extension token.
     */
    function _beforeTransfer(
        address,
        /* sender */
        address,
        /* recipient */
        uint256 /* amount */
    )
        internal
        view
        override
    {
        // Enforce Newton Policy protection when enabled
        // Note: This protects both transfer() and transferFrom() since transferFrom calls _transfer
        if (_getERC20ProtectedProxyEnabled()) {
            if (address(_getERC20ProtectedProxy()) == address(0)) {
                revert ERC20ProtectedProxyNotSet();
            }
            if (msg.sender != address(_getERC20ProtectedProxy())) {
                revert OnlyERC20ProtectedProxy();
            }
        }
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address to which the tokens will be minted.
     * @param amount    The amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal override {
        NewtonMExtensionStorageStruct storage $ = _getNewtonMExtensionStorageLocation();

        // NOTE: Can be `unchecked` because the max amount of $M is never greater than `type(uint240).max`.
        unchecked {
            $.balanceOf[recipient] += amount;
            $.totalSupply += amount;
        }

        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev   Burns `amount` tokens from `account`.
     * @param account The address from which the tokens will be burned.
     * @param amount  The amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal override {
        NewtonMExtensionStorageStruct storage $ = _getNewtonMExtensionStorageLocation();

        // NOTE: Can be `unchecked` because `_revertIfInsufficientBalance` is used in MExtension.
        unchecked {
            $.balanceOf[account] -= amount;
            $.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev   Internal balance update function called on transfer.
     * @param sender    The sender's address.
     * @param recipient The recipient's address.
     * @param amount    The amount to be transferred.
     */
    function _update(address sender, address recipient, uint256 amount) internal override {
        NewtonMExtensionStorageStruct storage $ = _getNewtonMExtensionStorageLocation();

        // NOTE: Can be `unchecked` because `_revertIfInsufficientBalance` for `sender` is used in MExtension.
        unchecked {
            $.balanceOf[sender] -= amount;
            $.balanceOf[recipient] += amount;
        }
    }
}


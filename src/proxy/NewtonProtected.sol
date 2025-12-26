// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.27;

import {INewtonProtected} from "./INewtonProtected.sol";
import {MExtensionProtectedProxy} from "./MExtensionProtectedProxy.sol";

abstract contract NewtonProtected is INewtonProtected {
    /// @notice EIP-1967 proxy storage slot for the NewtonProtectedStorage struct
    /// @dev bytes32(uint256(keccak256("newton.storage.newtonprotected")) - 1) & ~bytes32(uint256(0xff))
    bytes32 private constant NEWTON_POLICY_PROTECTED_STORAGE_SLOT =
        0xec02d7b37050f11d416bb7e4d9c116b45bab751f353354d371468453a2600a00;

    /// @notice Storage struct for Newton Policy Protected functionality
    struct NewtonProtectedStorage {
        bool erc20ProtectedProxyEnabled;
        MExtensionProtectedProxy erc20ProtectedProxy;
    }

    // Custom errors
    error ERC20ProtectedProxyNotSet();
    error OnlyERC20ProtectedProxy();

    event ERC20ProtectedProxySet(address indexed erc20ProtectedProxy);
    event ERC20ProtectedProxyEnabled(bool enabled);

    modifier onlyERC20ProtectedProxy() {
        if (_getERC20ProtectedProxyEnabled()) {
            if (address(_getERC20ProtectedProxy()) == address(0)) {
                revert ERC20ProtectedProxyNotSet();
            }
            if (msg.sender != address(_getERC20ProtectedProxy())) {
                revert OnlyERC20ProtectedProxy();
            }
        }
        _;
    }

    /// @notice Get the storage struct from the EIP-1967 slot
    function _getNewtonProtectedStorage() internal pure returns (NewtonProtectedStorage storage ds) {
        bytes32 slot = NEWTON_POLICY_PROTECTED_STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }

    function getERC20ProtectedProxy() external view returns (MExtensionProtectedProxy) {
        return _getERC20ProtectedProxy();
    }

    function _getERC20ProtectedProxy() internal view returns (MExtensionProtectedProxy) {
        return _getNewtonProtectedStorage().erc20ProtectedProxy;
    }

    function setERC20ProtectedProxy(address proxy) external virtual {
        _setERC20ProtectedProxy(proxy);
    }

    function _setERC20ProtectedProxy(address proxy) internal {
        _getNewtonProtectedStorage().erc20ProtectedProxy = MExtensionProtectedProxy(proxy);
    }

    function enableERC20ProtectedProxy() external virtual {
        _setERC20ProtectedProxyEnabled(true);
        emit ERC20ProtectedProxyEnabled(true);
    }

    function disableERC20ProtectedProxy() external virtual {
        _setERC20ProtectedProxyEnabled(false);
        emit ERC20ProtectedProxyEnabled(false);
    }

    function _getERC20ProtectedProxyEnabled() internal view returns (bool) {
        return _getNewtonProtectedStorage().erc20ProtectedProxyEnabled;
    }

    function _setERC20ProtectedProxyEnabled(bool enabled) internal {
        _getNewtonProtectedStorage().erc20ProtectedProxyEnabled = enabled;
    }
}


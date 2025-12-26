// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.27;

import {MExtensionProtectedProxy} from "./MExtensionProtectedProxy.sol";

/**
 * @title INewtonProtected
 * @notice Interface for contracts that can be protected by Newton Policy proxy functionality
 * @dev This interface defines the standard methods for managing Newton Policy proxy protection
 *      on contracts. It allows contracts to be wrapped with policy enforcement capabilities
 *      that can be dynamically enabled, disabled, and updated.
 */
interface INewtonProtected {
    /**
     * @notice Retrieves the current Newton Policy proxy address
     * @return The address of the currently configured Newton Policy proxy, or address(0) if none is set
     * @dev This function should return the proxy address that handles policy enforcement
     */
    function getERC20ProtectedProxy() external view returns (MExtensionProtectedProxy);

    /**
     * @notice Sets a new Newton Policy proxy address
     * @param proxy The address of the new Newton Policy proxy to use
     * @dev This function allows updating the policy proxy address. The caller should have
     *      appropriate permissions to modify the proxy configuration.
     * @dev Setting the proxy address does not automatically enable policy protection
     */
    function setERC20ProtectedProxy(address proxy) external;

    /**
     * @notice Enables Newton Policy proxy protection
     * @dev This function activates policy enforcement through the configured proxy.
     *      All function calls will be routed through the policy proxy for validation.
     * @dev Requires that a valid proxy address has been set via setERC20ProtectedProxy()
     */
    function enableERC20ProtectedProxy() external;

    /**
     * @notice Disables Newton Policy proxy protection
     * @dev This function deactivates policy enforcement, allowing direct function calls
     *      to bypass the policy proxy. The proxy address remains configured but inactive.
     */
    function disableERC20ProtectedProxy() external;
}


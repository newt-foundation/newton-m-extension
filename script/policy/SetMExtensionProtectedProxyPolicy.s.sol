// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {INewtonPolicy} from "newton-contracts/interfaces/INewtonPolicy.sol";

import {INewtonProtected} from "../../src/proxy/INewtonProtected.sol";

interface IPolicyClient {
    function setPolicy(INewtonPolicy.PolicyConfig calldata policyConfig) external returns (bytes32);
}

/// @notice Convenience script to set Newton Policy params on a deployed MExtensionProtectedProxy (policy client).
///
/// Required env vars:
/// - PRIVATE_KEY
/// - RPC_URL (or pass --rpc-url)
/// - EXPIRE_AFTER (uint, seconds)
/// - PARAMS_FILE (path to file; contents are passed as raw bytes to policyParams)
///
/// Choose one of:
/// - POLICY_CLIENT: address of the deployed MExtensionProtectedProxy
/// - TOKEN_PROXY:   address of the NewtonMExtension TransparentUpgradeableProxy (we'll read getERC20ProtectedProxy())
///
/// Notes:
/// - This calls `setPolicy(PolicyConfig)` on the policy client, which is `onlyPolicyClientOwner` gated.
/// - `PARAMS_FILE` is treated as raw bytes (typically JSON text); the policy itself interprets it.
contract SetMExtensionProtectedProxyPolicy is Script {
    function run() external returns (address policyClient, bytes32 policyId) {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        uint256 expireAfterRaw = vm.envUint("EXPIRE_AFTER");
        require(expireAfterRaw <= type(uint32).max, "EXPIRE_AFTER too large for uint32");

        string memory paramsFile = vm.envOr("PARAMS_FILE", string("sample_client_params.json"));
        require(bytes(paramsFile).length != 0, "PARAMS_FILE is required");

        policyClient = vm.envOr("POLICY_CLIENT", address(0));
        if (policyClient == address(0)) {
            address tokenProxy = vm.envOr("TOKEN_PROXY", address(0));
            require(tokenProxy != address(0), "Set POLICY_CLIENT or TOKEN_PROXY");
            policyClient = address(INewtonProtected(tokenProxy).getERC20ProtectedProxy());
        }

        bytes memory params = bytes(vm.readFile(paramsFile));
        INewtonPolicy.PolicyConfig memory config =
            INewtonPolicy.PolicyConfig({policyParams: params, expireAfter: uint32(expireAfterRaw)});

        vm.startBroadcast(deployer);
        policyId = IPolicyClient(policyClient).setPolicy(config);
        vm.stopBroadcast();
    }
}



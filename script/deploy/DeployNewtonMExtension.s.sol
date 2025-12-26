// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import {DeployBase} from "./DeployBase.s.sol";

import {NewtonMExtension} from "../../src/NewtonMExtension.sol";
import {MExtensionProtectedProxy} from "../../src/proxy/MExtensionProtectedProxy.sol";
import {console2} from "forge-std/console2.sol";

/// @notice Deploys a NewtonMExtension behind a transparent upgradeable proxy, then deploys the
///         Newton Policy enforcement proxy (MExtensionProtectedProxy) and wires them together.
///
/// Env vars expected:
/// - PRIVATE_KEY
/// - CONTRACT_NAME            (used for CREATE3 salt for the token proxy)
/// - EXTENSION_NAME           (ERC20 name)
/// - EXTENSION_SYMBOL         (ERC20 symbol)
/// - ADMIN                   (token proxy admin/owner, used by the Create3 Transparent proxy helper)
/// - SWAP_FACILITY            (optional if deployments/<chainId>.json has swapFacility set)
/// - POLICY_TASK_MANAGER      (Newton PolicyTaskManager address)
/// - POLICY                   (Newton Policy address)
/// - POLICY_CLIENT_OWNER      (owner for NewtonPolicyClient inside MExtensionProtectedProxy)
/// Optional:
/// - PROTECTED_PROXY_SALT     (defaults to "NewtonMExtensionProtectedProxy")
contract DeployNewtonMExtension is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        string memory contractName = vm.envString("CONTRACT_NAME");
        string memory extensionName = vm.envString("EXTENSION_NAME");
        string memory extensionSymbol = vm.envString("EXTENSION_SYMBOL");

        address admin = vm.envAddress("ADMIN");

        address policyTaskManager = vm.envAddress("POLICY_TASK_MANAGER");
        address policy = vm.envAddress("POLICY");
        address policyClientOwner = vm.envAddress("POLICY_CLIENT_OWNER");

        string memory protectedProxySalt = vm.envOr("PROTECTED_PROXY_SALT", string("NewtonMExtensionProtectedProxy"));

        // Verify predicted address (if PREDICTED_ADDRESS env var is set)
        if (_shouldVerifyPredictedAddress()) {
            _verifyPredictedAddress(deployer, contractName);
        }

        vm.startBroadcast(deployer);

        // 1) Deploy NewtonMExtension implementation (constructor args are immutable: mToken + swapFacility)
        DeployConfig memory config = _getDeployConfig(block.chainid);
        address implementation = address(new NewtonMExtension(config.mToken, _getSwapFacility()));

        // 2) Deploy token transparent proxy (this is the ERC20 users will interact with)
        address tokenProxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(NewtonMExtension.initialize.selector, extensionName, extensionSymbol, admin),
            _computeSalt(deployer, contractName)
        );

        // 3) Deploy policy enforcement proxy (this is the `proxyAddress` expected by setERC20ProtectedProxy)
        address protectedProxy = _deployCreate3(
            abi.encodePacked(
                type(MExtensionProtectedProxy).creationCode,
                abi.encode(tokenProxy, policyTaskManager, policy, policyClientOwner)
            ),
            _computeSalt(deployer, protectedProxySalt)
        );

        // 4) Wire up NewtonProtected -> MExtensionProtectedProxy and enable enforcement
        NewtonMExtension(tokenProxy).setERC20ProtectedProxy(protectedProxy);
        NewtonMExtension(tokenProxy).enableERC20ProtectedProxy();

        vm.stopBroadcast();

        console2.log("================================================================================");
        console2.log("DeployNewtonMExtension complete");
        console2.log("--------------------------------------------------------------------------------");
        console2.log("NewtonMExtension implementation: ", implementation);
        console2.log("ERC20 token proxy (TransparentUpgradeableProxy): ", tokenProxy);
        console2.log("Policy client (MExtensionProtectedProxy): ", protectedProxy);
        console2.log("================================================================================");

        // Persist the token proxy address in deployments/<chainId>.json under EXTENSION_NAME
        _writeDeployment(block.chainid, _getExtensionName(), tokenProxy);
    }
}



// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

import {NewtonMessage} from "newton-contracts/core/NewtonMessage.sol";
import {NewtonPolicyClient} from "newton-contracts/mixins/NewtonPolicyClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MExtensionProtectedProxy is NewtonPolicyClient {
    error InvalidAttestation();

    IERC20 private _token;

    constructor(address token, address policyTaskManager, address policy, address policyClientOwner) {
        _initNewtonPolicyClient(policyTaskManager, policy, policyClientOwner);
        _token = IERC20(token);
    }

    // IERC20.transfer(address to, uint256 amount) external returns (bool);
    function transfer(NewtonMessage.Attestation calldata attestation) external returns (bool) {
        require(_validateAttestation(attestation), InvalidAttestation());
        return _token.transferFrom(attestation.intent.from, attestation.intent.to, attestation.intent.value);
    }

    // IERC20.approve(address spender, uint256 amount) external returns (bool);
    function approve(NewtonMessage.Attestation calldata attestation) external returns (bool) {
        require(_validateAttestation(attestation), InvalidAttestation());
        return _token.approve(attestation.intent.to, attestation.intent.value);
    }

    // IERC20.transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferFrom(NewtonMessage.Attestation calldata attestation) external returns (bool) {
        require(_validateAttestation(attestation), InvalidAttestation());
        return _token.transferFrom(attestation.intent.from, attestation.intent.to, attestation.intent.value);
    }

    // Mint function for MExtension tokens
    function mint(NewtonMessage.Attestation calldata attestation) external {
        require(_validateAttestation(attestation), InvalidAttestation());
        // Cast to address to call mint function
        // Note: This assumes the token implements a mint(address, uint256) function
        (bool success, bytes memory returnData) = address(_token).call(
            abi.encodeWithSignature("mint(address,uint256)", attestation.intent.to, attestation.intent.value)
        );
        require(success, "Mint failed");
    }

    // Burn function for MExtension tokens
    function burn(NewtonMessage.Attestation calldata attestation) external {
        require(_validateAttestation(attestation), InvalidAttestation());
        // Cast to address to call burn function
        // Note: This assumes the token implements a burn(address, uint256) function
        (bool success, bytes memory returnData) = address(_token).call(
            abi.encodeWithSignature("burn(address,uint256)", attestation.intent.from, attestation.intent.value)
        );
        require(success, "Burn failed");
    }
}


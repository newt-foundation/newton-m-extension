# NewtonMExtension

**NewtonMExtension** is an upgradeable ERC-20 token contract that wraps the yield-bearing `$M` token into a non-rebasing variant with **Newton Policy protection**. All critical operations (transfer, approve, transferFrom, mint, and burn) are guarded by Newton Policy attestations, enabling decentralized, verifiable policy enforcement for token operations.

The contract is designed to be deployed behind transparent upgradeable proxies and integrates with the M Extension framework's `SwapFacility` for wrapping and unwrapping operations.

---

## Overview

NewtonMExtension extends the `MExtension` base contract and adds Newton Policy protection through the `NewtonProtected` mixin. When policy protection is enabled, all protected functions can only be called through the `MExtensionProtectedProxy`, which validates Newton Policy attestations before executing operations.

### Key Features

- **Newton Policy Protection**: All critical token operations require valid policy attestations
- **Non-Rebasing Token**: Wraps `$M` into a stable, non-rebasing ERC-20 token
- **Upgradeable**: Deployed behind transparent upgradeable proxies
- **SwapFacility Integration**: Works with the M Extension framework's SwapFacility for wrapping/unwrapping

---

## Architecture

### Core Contracts

#### `NewtonMExtension`

The main token contract that:

- Extends `MExtension` for wrapping/unwrapping functionality
- Implements `NewtonProtected` for policy enforcement
- Stores balances and total supply using ERC-7201 namespaced storage

#### `MExtensionProtectedProxy`

The proxy contract that:

- Validates Newton Policy attestations
- Routes validated calls to `NewtonMExtension`
- Implements `NewtonPolicyClient` for policy management

#### `NewtonProtected`

Abstract contract providing:

- Storage management for proxy configuration
- `onlyERC20ProtectedProxy` modifier for function protection
- Proxy enable/disable functionality

---

## Protected Functions

When policy protection is enabled, the following functions can only be called through `MExtensionProtectedProxy` with valid attestations:

### ERC-20 Operations

- **`transfer(address to, uint256 amount)`** - Transfer tokens to another address
- **`approve(address spender, uint256 amount)`** - Approve spender to transfer tokens
- **`transferFrom(address from, address to, uint256 amount)`** - Transfer tokens on behalf of another address

### Token Lifecycle

- **`mint(address recipient, uint256 amount)`** - Mint new tokens to a recipient
- **`burn(address account, uint256 amount)`** - Burn tokens from an account

All protected functions revert if:

- Policy protection is enabled but no proxy is set
- The caller is not the configured `MExtensionProtectedProxy`
- The attestation validation fails

---

## Usage

### Initialization

```solidity
function initialize(
    string memory name,
    string memory symbol,
    address owner
) public initializer
```

### Setting Up Policy Protection

1. Deploy `MExtensionProtectedProxy` with:
   - Token address (NewtonMExtension)
   - Policy task manager address
   - Policy address
   - Policy client owner

2. Configure NewtonMExtension:

   ```solidity
   newtonMExtension.setERC20ProtectedProxy(proxyAddress);
   newtonMExtension.enableERC20ProtectedProxy();
   ```

3. Disable protection (if needed):

   ```solidity
   newtonMExtension.disableERC20ProtectedProxy();
   ```

### Executing Protected Operations

All protected operations must go through the proxy with valid attestations:

```solidity
// Example: Transfer with attestation
MExtensionProtectedProxy proxy = newtonMExtension.getERC20ProtectedProxy();
proxy.transfer(attestation);

// Example: Mint with attestation
proxy.mint(attestation);
```

The attestation must be validated by the Newton Policy system before the operation executes.

---

## Storage Layout

NewtonMExtension uses ERC-7201 namespaced storage to avoid conflicts:

- **Storage Location**: `M0.storage.NewtonMExtension`
- **Storage Slot**: `0x5db7832de89694644441703dce434ce616bfd1332a090f87aa90736d132321400`

The storage struct contains:

- `totalSupply`: Total token supply
- `balanceOf`: Mapping of account balances

---

## Integration with M Extension Framework

NewtonMExtension integrates with the M Extension framework:

- **Wrapping**: Users deposit `$M` through `SwapFacility`, which calls `wrap()` to mint NewtonMExtension tokens
- **Unwrapping**: Users call `SwapFacility` to unwrap NewtonMExtension tokens back to `$M`
- **Yield**: Yield accrues on the underlying `$M` balance held by the contract

The `SwapFacility` is the exclusive entry point for wrapping and unwrapping operations, as enforced by the `onlySwapFacility` modifier inherited from `MExtension`.

---

## Security Considerations

- **Policy Protection**: When enabled, all protected functions require valid Newton Policy attestations
- **Proxy Validation**: The proxy validates attestations before forwarding calls to the token contract
- **Upgradeable**: Contracts are deployed behind transparent proxies, allowing for upgrades while maintaining storage compatibility
- **Storage Isolation**: Uses ERC-7201 namespaced storage to prevent storage slot conflicts

---

## Dependencies

- `newton-contracts`: Newton Policy system for attestation validation
- `MExtension`: Base contract for M token wrapping functionality
- OpenZeppelin: Upgradeable contracts and ERC-20 implementation

# NewtonMExtension

**NewtonMExtension** is an upgradeable ERC-20 token contract that wraps the yield-bearing `$M` token into a non-rebasing variant with **Newton Policy protection**. All critical operations (transfer, approve, transferFrom, mint, and burn) are guarded by Newton Policy attestations, enabling decentralized, verifiable policy enforcement for token operations.

The contract is designed to be deployed behind transparent upgradeable proxies and integrates with the M Extension framework's `SwapFacility` for wrapping and unwrapping operations.

---

## Overview

NewtonMExtension extends the `MExtension` base contract and adds Newton Policy protection through the `NewtonProtected` mixin. This implementation demonstrates the **proxy pattern** for integrating Newton Policy attestation validation - one of two primary integration approaches available to developers.

When policy protection is enabled, all protected functions can only be called through the `MExtensionProtectedProxy`, which validates Newton Policy attestations before executing operations. The integration pattern follows a similar approach to [Chainlink oracle integrations](https://docs.chain.link/data-feeds/using-data-feeds), where contracts extend from a base client class (`NewtonPolicyClient`) that provides attestation validation helpers.

### Key Features

- **Newton Policy Protection**: All critical token operations require valid policy attestations containing the exact intent with expiration
- **Non-Rebasing Token**: Wraps `$M` into a stable, non-rebasing ERC-20 token
- **Upgradeable**: Deployed behind transparent upgradeable proxies
- **SwapFacility Integration**: Works with the M Extension framework's SwapFacility for wrapping/unwrapping
- **Flexible Integration**: Demonstrates proxy pattern; direct inheritance pattern also supported

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

- Validates Newton Policy attestations before forwarding calls
- Routes validated calls to `NewtonMExtension`
- Implements `NewtonPolicyClient` for policy management
- Handles `msg.sender` context: the proxy receives user calls and forwards them with proper context after validation

#### `NewtonProtected`

Abstract contract providing:

- Storage management for proxy configuration
- `onlyERC20ProtectedProxy` modifier for function protection
- Proxy enable/disable functionality

---

## Attestation Validation

Newton Policy attestations contain the **exact intent** that is approved, along with an expiration block number. The attestation structure includes:

- **Intent Data**: The complete function call data (function selector + encoded parameters)
- **Expiration**: Block number after which the attestation is no longer valid
- **BLS Signature**: Protocol-validated signature of the intent hash that the Newton Policy system is attesting for

This ensures that each attestation is purpose-specific and cannot be reused for different operations. When `_validateAttestation()` is called, the Newton Policy validates that:

1. The attestation's intent matches the actual function call being made
2. The attestation has not expired (current block <= expiration block)
3. The BLS signature is valid for the intent hash

For example, a transfer attestation contains the recipient address in the intent data. You cannot use a transfer attestation intended for `addressA` to execute a transfer to `addressB` - the intent validation would fail.

The integration pattern mirrors [Chainlink oracle integrations](https://docs.chain.link/data-feeds/using-data-feeds), where contracts extend `NewtonPolicyClient` to access attestation validation helpers that ensure correct usage of the protocol.

---

## Integration Patterns

NewtonMExtension demonstrates the **proxy pattern** for integrating Newton Policy protection, but developers have two primary integration approaches:

### 1. Proxy Pattern (Demonstrated Here)

The proxy pattern minimizes code changes to existing contracts:

- Token contract extends `NewtonProtected` mixin
- Protected functions use `onlyERC20ProtectedProxy` modifier
- Separate `MExtensionProtectedProxy` contract handles attestation validation
- Proxy inherits from `NewtonPolicyClient` for validation helpers
- Users interact with the proxy, which validates attestations then forwards calls to the token

**Advantages**: Minimal changes to existing token logic, clear separation of concerns

### 2. Direct Inheritance Pattern

Alternatively, contracts can integrate directly:

- Token contract extends `NewtonPolicyClient` directly
- Protected functions call `_validateAttestation()` inline
- No separate proxy contract needed
- Users interact directly with the token contract

**Advantages**: Simpler architecture, fewer contracts to deploy

Both patterns provide the same security guarantees and require valid Newton Policy attestations for protected operations.

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
- The attestation validation fails (intent mismatch, expired, or invalid signature)

### How msg.sender Works with the Proxy

When using the proxy pattern, the `msg.sender` context is handled as follows:

1. User calls proxy function (e.g., `proxy.transfer(attestation)`)
2. Proxy validates the attestation against the intent data
3. Proxy forwards the call to the token contract with the original user context
4. Token contract receives the call from the proxy and validates `msg.sender == proxy`
5. The proxy ensures proper `msg.sender` propagation for functions like `approve` and `transferFrom`

The proxy acts as a trusted intermediary that validates attestations before allowing operations to proceed with the correct sender context.

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

The attestation must contain the exact intent (function call data including all parameters) and be validated by the Newton Policy system before the operation executes. Each attestation is purpose-specific - a transfer attestation for recipient A cannot be used to transfer to recipient B.

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

## Setup and Installation

### Installing Dependencies

When cloning this repository for the first time:

```bash
# Install npm dependencies (this automatically applies patches via postinstall hook)
npm install

# Install Foundry dependencies
forge install
```

**Patches are automatically applied** via:

1. **npm postinstall hook** - Runs automatically after `npm install`
2. **Build process** - Patches are checked/applied before each build

### Automatic Patch Application

This repository includes patches for the `newton-contracts` dependency to fix compilation issues with Solidity 0.8.27. The patches are automatically applied:

- **After `npm install`** - via npm's `postinstall` script hook
- **During builds** - via `build.sh` which checks and applies patches before compiling
- **No manual steps required** - patches apply automatically when needed

The patches fix:

1. **SlashingLib.sol**: Updates Math import to use correct OpenZeppelin version
2. **NewtonPolicyFactory.sol**: Fixes ProxyAdmin constructor call  
3. **foundry.toml**: Updates OpenZeppelin remapping to versioned directory

### Manual Patch Application (if needed)

If you need to manually apply patches:

```bash
node scripts/apply-patches.js
```

The script is idempotent - it safely skips patches that are already applied.

### Git Status: Modified Submodules

After patches are applied, `git status` will show `lib/newton-contracts` and `lib/wrapped-m-token` as modified. **This is expected** - patches modify files within the submodules to fix compilation issues.

To ignore these submodule changes in git:

```bash
# Configure git to ignore submodule changes
git config submodule.lib/newton-contracts.ignore all
git config submodule.lib/wrapped-m-token.ignore all
```

Or add to `.git/config`:

```ini
[submodule "lib/newton-contracts"]
    ignore = all
[submodule "lib/wrapped-m-token"]
    ignore = all
```

The patches are version-controlled in `patches/newton-contracts/` and `patches/wrapped-m-token/`, so modifications are reproducible and don't need to be committed to the submodules.

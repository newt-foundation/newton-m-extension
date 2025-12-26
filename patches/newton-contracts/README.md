# Newton Contracts Patches

This directory contains patches for the `newton-contracts` dependency to fix compilation issues with Solidity 0.8.27.

## Patches

### 0001-fix-slashinglib-math-import.patch

Fixes the Math import in `SlashingLib.sol` to use the correct OpenZeppelin version that includes `Math.Rounding.Up`.

**Issue**: The `@openzeppelin/` remapping was resolving to a version without the `Rounding.Up` enum value.

**Fix**: Changes the import to use a relative path pointing to the versioned OpenZeppelin directory (`openzeppelin-contracts-v4.9.0`).

### 0002-fix-proxyadmin-constructor.patch

Fixes the `ProxyAdmin` constructor call in `NewtonPolicyFactory.sol` to include the required owner parameter.

**Issue**: OpenZeppelin v4.9.0's `ProxyAdmin` constructor requires an initial owner parameter.

**Fix**: Adds the `owner` parameter to the `ProxyAdmin` constructor call.

### 0003-update-foundry-toml-remapping.patch

Updates the `@openzeppelin/` remapping in newton-contracts' `foundry.toml` to point to the versioned directory.

**Issue**: The remapping was pointing to a non-versioned directory that may not have the correct OpenZeppelin version.

**Fix**: Updates the remapping to explicitly use `openzeppelin-contracts-v4.9.0`.

## Applying Patches

Patches are automatically applied when you run:

```bash
make install-deps
# or
make update
```

To manually apply patches:

```bash
node scripts/apply-patches.js
```

## Verifying Patches

To check if patches are applied:

```bash
cd lib/newton-contracts
git status
```

Modified files should show up if patches are applied.

## Updating Patches

If newton-contracts is updated and patches need to be regenerated:

1. Make changes to the dependency files
2. Generate patches:

   ```bash
   cd lib/newton-contracts
   git diff > ../../patches/newton-contracts/0001-patch-name.patch
   ```

3. Test patches on a fresh clone
4. Commit patches to the repository

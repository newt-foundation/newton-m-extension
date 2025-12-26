# Wrapped M Token Patches

This directory contains patches for the `wrapped-m-token` dependency to fix compilation issues with Solidity 0.8.27.

## Patches

### 0001-update-solidity-version-to-0.8.27.patch

Updates all Solidity files and foundry.toml configuration from Solidity 0.8.26 to 0.8.27.

**Issue**: Solidity version 0.8.26 does not exist (versions jump from 0.8.25 to 0.8.27). The dependency specifies 0.8.26 which causes compilation errors.

**Fix**: Updates all `pragma solidity 0.8.26;` statements to `pragma solidity 0.8.27;` and updates `solc_version` in foundry.toml files.

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
cd lib/wrapped-m-token
git status
```

Modified files should show up if patches are applied.

## Updating Patches

If wrapped-m-token is updated and patches need to be regenerated:

1. Make changes to the dependency files
2. Generate patches:

   ```bash
   cd lib/wrapped-m-token
   git diff > ../../patches/wrapped-m-token/0001-patch-name.patch
   ```

3. Test patches on a fresh clone
4. Commit patches to the repository


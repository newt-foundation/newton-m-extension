#!/usr/bin/env node
/**
 * Automatically applies patches to newton-contracts dependency
 * Runs as npm postinstall hook to ensure patches are applied after dependency installation
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');

function exec(command, options = {}) {
  try {
    return execSync(command, { 
      cwd: PROJECT_ROOT,
      stdio: 'inherit',
      ...options 
    });
  } catch (error) {
    if (options.ignoreErrors) {
      return null;
    }
    throw error;
  }
}

function applyPatchesToDependency(dependencyName, patchesDir, dependencyDir) {
  // Check if dependency directory exists
  if (!fs.existsSync(dependencyDir)) {
    console.log(`ℹ ${dependencyName} not found, skipping patches (run "forge install" first)`);
    return;
  }

  // Check if patches directory exists
  if (!fs.existsSync(patchesDir)) {
    console.log(`ℹ No patches directory found for ${dependencyName}, skipping`);
    return;
  }

  // Get all patch files
  const patchFiles = fs.readdirSync(patchesDir)
    .filter(file => file.endsWith('.patch'))
    .sort()
    .map(file => path.join(patchesDir, file));

  if (patchFiles.length === 0) {
    console.log(`ℹ No patch files found for ${dependencyName}`);
    return;
  }

  console.log(`Applying ${patchFiles.length} patch(es) to ${dependencyName}...`);

  for (const patchFile of patchFiles) {
    const patchName = path.basename(patchFile);
    process.stdout.write(`  ${patchName}... `);

    try {
      // Try to apply the patch
      exec(`git -C "${dependencyDir}" apply --check "${patchFile}"`, { 
        stdio: 'pipe',
        ignoreErrors: true 
      });
      
      // Apply the patch
      exec(`git -C "${dependencyDir}" apply "${patchFile}"`, { 
        stdio: 'pipe' 
      });
      console.log('✓');
    } catch (error) {
      // Check if patch was already applied
      try {
        exec(`git -C "${dependencyDir}" apply --reverse --check "${patchFile}"`, { 
          stdio: 'pipe' 
        });
        console.log('⊙ (already applied)');
      } catch (reverseError) {
        console.log('✗ (failed or conflicts)');
        // Don't fail the build, just warn
        console.warn(`    Warning: Could not apply ${patchName}`);
      }
    }
  }
}

function applyPatches() {
  // Apply patches to newton-contracts
  const newtonPatchesDir = path.join(PROJECT_ROOT, 'patches', 'newton-contracts');
  const newtonContractsDir = path.join(PROJECT_ROOT, 'lib', 'newton-contracts');
  applyPatchesToDependency('newton-contracts', newtonPatchesDir, newtonContractsDir);

  // Apply patches to wrapped-m-token
  const wrappedPatchesDir = path.join(PROJECT_ROOT, 'patches', 'wrapped-m-token');
  const wrappedMTokenDir = path.join(PROJECT_ROOT, 'lib', 'wrapped-m-token');
  applyPatchesToDependency('wrapped-m-token', wrappedPatchesDir, wrappedMTokenDir);

  console.log('Patch application complete!');
}

// Only run if called directly (not when required as module)
if (require.main === module) {
  applyPatches();
}

module.exports = { applyPatches };


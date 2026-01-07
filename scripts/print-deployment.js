#!/usr/bin/env node
/**
 * Print deployment addresses from deployments/<chainId>.json
 *
 * Usage:
 *   node scripts/print-deployment.js <chainId> <extensionName>
 *
 * Prints:
 * - implementation (key: <extensionName>_Implementation)
 * - token proxy (key: <extensionName>)
 * - policy client (key: <extensionName>_PolicyClient)
 */

const fs = require("fs");
const path = require("path");

function die(msg) {
  console.error(msg);
  process.exit(1);
}

function main() {
  const [, , chainIdRaw, extensionName] = process.argv;
  if (!chainIdRaw) die("Missing chainId. Usage: node scripts/print-deployment.js <chainId> <extensionName>");
  if (!extensionName) die("Missing extensionName. Usage: node scripts/print-deployment.js <chainId> <extensionName>");

  const chainId = String(chainIdRaw).trim();
  const deploymentsPath = path.resolve(__dirname, "..", "deployments", `${chainId}.json`);
  if (!fs.existsSync(deploymentsPath)) die(`No deployments file found: ${deploymentsPath}`);

  const raw = fs.readFileSync(deploymentsPath, "utf8");
  let json;
  try {
    json = JSON.parse(raw);
  } catch (e) {
    die(`Failed to parse JSON: ${deploymentsPath}`);
  }

  const names = Array.isArray(json.extensionNames) ? json.extensionNames : [];
  const addrs = Array.isArray(json.extensionAddresses) ? json.extensionAddresses : [];

  function findAddress(key) {
    const idx = names.findIndex((n) => n === key);
    if (idx === -1) return null;
    return addrs[idx] ?? null;
  }

  const implementationKey = `${extensionName}_Implementation`;
  const tokenKey = extensionName;
  const policyClientKey = `${extensionName}_PolicyClient`;

  const implementation = findAddress(implementationKey);
  const token = findAddress(tokenKey);
  const policyClient = findAddress(policyClientKey);

  // Print a short, stable summary at the end of the Make target output.
  console.log("");
  console.log("=== Deployment addresses (from deployments/%s.json) ===", chainId);

  if (implementation) console.log("%s: %s", implementationKey, implementation);
  else console.log("%s: (not found)", implementationKey);

  if (token) console.log("%s: %s", tokenKey, token);
  else console.log("%s: (not found)", tokenKey);

  if (policyClient) console.log("%s: %s", policyClientKey, policyClient);
  else console.log("%s: (not found)", policyClientKey);
}

main();


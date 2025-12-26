#!/usr/bin/env bash
set -e

sizes=false

while getopts p:s flag; do
	case "${flag}" in
	p) profile=${OPTARG} ;;
	s) sizes=true ;;
	esac
done

export FOUNDRY_PROFILE=$profile
echo Using profile: $FOUNDRY_PROFILE

# Apply patches before building (if patches exist and newton-contracts is present)
if [ -d "patches/newton-contracts" ] && [ -d "lib/newton-contracts" ]; then
	node scripts/apply-patches.js 2>/dev/null || true
fi

if [ "$sizes" = false ]; then
	forge build --skip '*/test/**' '*/script/**' --extra-output-files abi
else
	forge build --skip '*/test/**' '*/script/**' --extra-output-files abi --sizes
fi

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.27;

import { ForcedTransferable } from "../../src/components/forcedTransferable/ForcedTransferable.sol";

contract ForcedTransferableHarness is ForcedTransferable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address forceTransferManager) public initializer {
        __ForcedTransferable_init(forceTransferManager);
    }
}

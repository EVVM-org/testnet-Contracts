// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {State} from "@evvm/testnet-contracts/contracts/state/State.sol";

abstract contract StateManagment {
    State state;

    constructor(address stateAddress) {
        state = State(stateAddress);
    }

    function reserveAsyncNonceToService(address user, uint256 nonce) external {
        state.reserveAsyncNonce(user, nonce, address(this));
    }

    function revokeAsyncNonceToService(address user, uint256 nonce) external {
        state.revokeAsyncNonce(user, nonce);
    }

    function getNextCurrentSyncNonce(
        address user
    ) external view returns (uint256) {
        return state.getNextCurrentSyncNonce(user);
    }

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return state.getIfUsedAsyncNonce(user, nonce);
    }

    function _changeStateAddress(address newStateAddress) internal virtual {
        state = State(newStateAddress);
    }
}

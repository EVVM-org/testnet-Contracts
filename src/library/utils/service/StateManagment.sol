// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title State Management for EVVM Services
 * @author Mate labs
 * @notice Abstract contract for State.sol nonce management (async/sync)
 * @dev Provides nonce reservation, revocation, and query functions. Async nonces: user-chosen, must reserve. Sync nonces: sequential, auto-increment.
 */

import {IState} from "@evvm/testnet-contracts/interfaces/IState.sol";

abstract contract StateManagment {
    /// @notice State contract reference
    /// @dev Used for all nonce operations
    IState state;

    /**
     * @notice Initializes State.sol integration
     * @param stateAddress Address of State.sol contract
     */
    constructor(address stateAddress) {
        state = IState(stateAddress);
    }

    /**
     * @notice Reserves async nonce for user and this service exclusively
     * @dev Calls state.reserveAsyncNonce(user, nonce, address(this)). Nonce can be revoked before use.
     * @param user User address reserving nonce
     * @param nonce Async nonce number to reserve
     */
    function reserveAsyncNonceToService(address user, uint256 nonce) external {
        state.reserveAsyncNonce(user, nonce, address(this));
    }

    /**
     * @notice Revokes reserved async nonce before use
     * @dev Calls state.revokeAsyncNonce(user, nonce). Cannot revoke consumed nonces.
     * @param user User address that reserved nonce
     * @param nonce Async nonce number to revoke
     */
    function revokeAsyncNonceToService(address user, uint256 nonce) external {
        state.revokeAsyncNonce(user, nonce);
    }

    /**
     * @notice Gets next sequential sync nonce for user
     * @dev View function returning state.getNextCurrentSyncNonce(user). Auto-increments after each use.
     * @param user User address to query
     * @return Next sync nonce for user
     */
    function getNextCurrentSyncNonce(
        address user
    ) external view returns (uint256) {
        return state.getNextCurrentSyncNonce(user);
    }

    /**
     * @notice Checks if async nonce was consumed
     * @dev View function returning state.getIfUsedAsyncNonce(user, nonce). Reserved nonces return false until consumed.
     * @param user User address to query
     * @param nonce Async nonce to check
     * @return true if consumed, false if available/reserved
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return state.getIfUsedAsyncNonce(user, nonce);
    }

    /**
     * @notice Updates State.sol contract address for governance-controlled upgrades
     * @dev Should be protected with onlyAdmin and time-delay. Nonce states remain in old contract.
     * @param newStateAddress New State.sol contract address
     */
    function _changeStateAddress(address newStateAddress) internal virtual {
        state = IState(newStateAddress);
    }
}

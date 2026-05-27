// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title P2PSwapError - Error Definitions for P2P Swap service
 * @author Mate labs
 * @notice Custom error definitions for P2PSwap.sol contract
 * @dev Gas-efficient custom errors for all P2PSwap.sol failure conditions.
 */
library P2PSwapError {
    /// @notice Thrown when the caller is not the order seller.
    error NotTheSeller();
    /// @notice Thrown when the referenced order does not exist.
    error OrderIsUnavailable();
    /// @notice Thrown when the payment amount is below the minimum required.
    error InsufficientPayment();
    /// @notice Thrown when trying to fill more than the available amount in the order.
    error InsufficientAmountToFill();
    /// @notice Thrown when the sender is not the current admin for admin-restricted functions.
    error SenderIsNotAdmin();
    /// @notice Thrown when the provided address input is invalid (e.g., zero address or not a contract when expected).
    error IncorrectAddressInput();
    /// @notice Thrown when the order is not in a state that allows it to be accepted.
    error ProposalNotReadyToAccept();
    /// @notice Thrown when the sender is not the proposed admin for an admin change.
    error SenderIsNotTheProposedAdmin();
    /// @notice Thrown when the provided basis points value is invalid (e.g., exceeds 100% or has more than 2 decimal places).
    error InvalidBasisPoints();
    // @notice Thrown when the provided amount is zero, which is not allowed for certain operations.
    error ZeroAmount();
    // @notice Thrown when the provided token pair is the same, which is not allowed for swaps.
    error SameTokenPair();
    // @notice Thrown when the provided order ID is invalid (e.g., zero or does not correspond to an existing order).
    error UnexpectedBehavior();
}

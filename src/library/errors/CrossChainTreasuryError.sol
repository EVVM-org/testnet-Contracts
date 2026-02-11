// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title ErrorsLib
 * @author Mate labs
 * @notice Custom error definitions for Treasury Cross-Chain operations
 * @dev Centralized error library for both TreasuryHostChainStation and TreasuryExternalChainStation
 *      Provides gas-efficient custom errors with descriptive names for better debugging
 *      and user experience across all cross-chain treasury operations
 */
library CrossChainTreasuryError {
    /// @notice Thrown when a user has insufficient balance for the requested operation
    /// @dev Used in withdraw operations and Fisher bridge transfers when EVVM balance is too low
    error InsufficientBalance();

    /// @notice Thrown when attempting to withdraw or bridge the Principal Token (MATE)
    /// @dev Principal Token is reserved for EVVM ecosystem operations and cannot be withdrawn cross-chain
    error PrincipalTokenIsNotWithdrawable();

    /// @notice Thrown when deposit amount validation fails
    /// @dev Generic validation error for deposit amount issues beyond zero checks
    error InvalidDepositAmount();

    /// @notice Thrown when deposit or transfer amount is zero or negative
    /// @dev Prevents meaningless transactions and ensures positive value transfers
    error DepositAmountMustBeGreaterThanZero();

    /// @notice Thrown when Hyperlane message sender is not the authorized mailbox contract
    /// @dev Security check to prevent unauthorized cross-chain message execution via Hyperlane
    error MailboxNotAuthorized();

    /// @notice Thrown when cross-chain message sender is not the authorized counterpart station
    /// @dev Security check across all protocols (Hyperlane, LayerZero, Axelar) to prevent impersonation
    error SenderNotAuthorized();

    /// @notice Thrown when cross-chain message originates from non-authorized chain
    /// @dev Prevents cross-chain attacks from unauthorized chains or wrong network configurations
    error ChainIdNotAuthorized();

    error WindowToChangeEvvmIDExpired();
}

// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title ErrorsLib
 * @author Mate Labs
 * @notice Library containing all custom error definitions for the Treasury contract
 * @dev This library is exclusive to the Treasury.sol contract and provides descriptive
 * error types for deposit and withdrawal operations.
 *
 * Error Categories:
 * - Balance Errors: Insufficient funds for operations
 * - Deposit Errors: Invalid deposit amounts or configurations
 * - Withdrawal Restrictions: Token withdrawal limitations
 */

library TreasuryError {
    //█ Balance Errors ███████████████████████████████████████████████████████████████████████████████

    /// @dev Thrown when a user attempts to withdraw more tokens than their available balance
    error InsufficientBalance();

    //█ Withdrawal Restriction Errors ████████████████████████████████████████████████████████████████

    /// @dev Thrown when attempting to withdraw Principal Tokens through the Treasury
    /// @notice Principal Tokens can only be transferred through EVVM pay operations, not direct withdrawal
    error PrincipalTokenIsNotWithdrawable();

    //█ Deposit Errors ███████████████████████████████████████████████████████████████████████████████

    /// @dev Thrown when the deposit amount doesn't match msg.value for ETH deposits,
    ///      or when msg.value is non-zero for ERC20 deposits
    error InvalidDepositAmount();

    /// @dev Thrown when attempting to deposit zero amount of tokens or ETH
    error DepositAmountMustBeGreaterThanZero();

    /// @dev Thrown when attempting to deposit blockchain native coin while also sending ERC20 tokens
    error DepositCoinWithToken();
}

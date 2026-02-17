// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title TreasuryError
 * @author Mate Labs
 * @notice Custom errors for Treasury.sol
 * @dev Gas-efficient error definitions for deposit/withdrawal operations.
 */

library TreasuryError {
    //█ Balance Errors ███████████████████████████████████████████████████████████████████████████████

    /// @dev Thrown when withdrawal amount > user balance
    error InsufficientBalance();

    //█ Withdrawal Restriction Errors ████████████████████████████████████████████████████████████████

    /// @dev Thrown when attempting to withdraw Principal Token (must use EVVM pay operations)
    error PrincipalTokenIsNotWithdrawable();

    //█ Deposit Errors ███████████████████████████████████████████████████████████████████████████████

    /// @dev Thrown when deposit amount != msg.value (ETH) or msg.value != 0 (ERC20)
    error InvalidDepositAmount();

    /// @dev Thrown when deposit amount == 0
    error DepositAmountMustBeGreaterThanZero();

    /// @dev Thrown when attempting to deposit both native coin and ERC20 simultaneously
    error DepositCoinWithToken();
}

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
    /// @notice Thrown when the caller is not the order seller (cancelOrder only).
    error NotTheSeller();
    /// @notice Thrown when the referenced order does not exist (seller == address(0)).
    error OrderIsUnavailable();
    /// @notice Thrown when netPayment is zero or totalPayment (netPayment + fee) exceeds amountInMax.
    error InsufficientPayment();
    /// @notice Thrown when trying to fill more than the available amount in the order (amountOut > amountAvailable).
    error InsufficientAmountToFill();
    /// @notice Thrown when the sender is not the current admin for admin-restricted functions.
    error SenderIsNotAdmin();
    /// @notice Thrown for invalid address/value inputs: zero address, current admin as new admin, or fee > 10_000 basis points.
    error IncorrectAddressInput();
    /// @notice Thrown when attempting to accept a proposal before the 1-day timelock has elapsed.
    error ProposalNotReadyToAccept();
    /// @notice Thrown when the sender is not the proposed admin for an admin change (acceptAdmin only).
    error SenderIsNotTheProposedAdmin();
    /// @notice Thrown when the sum of basis points (seller + service + mateStaker) does not equal 10_000.
    error InvalidBasisPoints();
    /// @notice Thrown when offeredAmount or requestedAmount is zero in makeOrder, or amountOut/amountInMax is zero in dispatchOrder.
    error ZeroAmount();
    /// @notice Thrown when offeredToken equals requestedToken in makeOrder.
    error SameTokenPair();
    /// @notice Thrown when no available order slot is found despite ordersAvailable < maxSlot (internal inconsistency).
    error UnexpectedBehavior();
    /// @notice Thrown when amountToWithdraw is zero in proposeWithdrawal.
    error IncorrectInput();
    /// @notice Thrown when amountToWithdraw exceeds totalFeesCollected[token] in proposeWithdrawal.
    error InsufficientAmount();
}

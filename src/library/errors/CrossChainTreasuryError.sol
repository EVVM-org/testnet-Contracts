// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title Cross-Chain Treasury Error Library
 * @author Mate labs
 * @notice Custom errors for cross-chain treasury operations
 * @dev Gas-efficient errors for TreasuryHostChainStation and TreasuryExternalChainStation. Independent from Core.sol (own nonces).
 */
library CrossChainTreasuryError {
    /// @dev Thrown when Core.sol balance < withdrawal amount (host chain only)
    error InsufficientBalance();

    /// @dev Thrown when attempting to withdraw/bridge Principal Token (MATE). Cannot leave host chain.
    error PrincipalTokenIsNotWithdrawable();

    /// @dev Thrown when deposit amount validation fails (bounds check or msg.value mismatch)
    error InvalidDepositAmount();

    /// @dev Thrown when deposit/bridge amount == 0
    error DepositAmountMustBeGreaterThanZero();

    /// @dev Thrown when msg.sender != Hyperlane mailbox in message handler
    error MailboxNotAuthorized();

    /// @dev Thrown when message sender address != authorized station (Hyperlane/LayerZero/Axelar validation)
    error SenderNotAuthorized();

    /// @dev Thrown when origin chain ID != configured chain (Hyperlane domain/LayerZero eid/Axelar chainName)
    error ChainIdNotAuthorized();

    /// @dev Thrown when setEvvmID called after grace period (windowTimeToChangeEvvmID)
     error WindowToChangeEvvmIDExpired();
}

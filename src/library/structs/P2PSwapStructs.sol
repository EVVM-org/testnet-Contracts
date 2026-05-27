// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {ProposalStructs} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 * @title P2P Swap Data Structures
 * @author Mate labs
 * @notice Core data structures for P2PSwap.sol order book (markets, orders, fees, operation metadata)
 * @dev All operations validated via Core.sol async nonces. Payments via Core.sol.
 */

library P2PSwapStructs {
    /**
     * @notice Market metadata for token pair trading
     * @dev Tracks order slot allocation and active order count.
     * @param maxSlot Highest slot number assigned
     * @param ordersAvailable Active order count
     * @param medianPrice Volume-weighted average price of the market
     */
    struct MarketInformation {
        uint256 maxSlot;
        uint256 ordersAvailable;
        uint256 medianPrice;
    }

    /**
     * @notice Core order data stored on-chain
     * @dev Minimal storage for gas efficiency. Token addresses inferred from market ID. Deleted orders: seller = address(0).
     * @param seller Order creator
     * @param offeredAmount Total amount of offeredToken placed in the order
     * @param requestedAmount Total amount of requestedToken expected for the full offer
     * @param amountAvailable Remaining amount of offeredToken available to be filled
     */
    struct Order {
        address seller;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 amountAvailable;
    }

    /**
     * @notice Extended order data for view functions
     * @dev Includes market and order IDs for UI display.
     * @param marketId Market containing order
     * @param orderId Order slot ID
     * @param seller Order creator
     * @param amountA Amount of tokenA offered
     * @param amountB Amount of tokenB requested
     */
    struct OrderForGetter {
        uint256 marketId;
        uint256 orderId;
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Fee distribution percentages for trades (basis points)
     * @dev Total must equal 10,000 (100.00%). Adjustable via time-delayed governance.
     * @param seller Basis points to order seller
     * @param service Basis points to P2PSwap service
     * @param mateStaker Basis points to staker
     */
    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    /**
     * @notice Time-delayed proposal for updating fee distribution percentages
     * @dev Uses the Percentage struct for current and proposed values.
     * @param current Currently active percentage split
     * @param proposed Proposed percentage split awaiting acceptance
     * @param proposalTime Timestamp when the proposal becomes acceptable
     */
    struct PercentageProposal {
        Percentage current;
        Percentage proposed;
        uint256 proposalTime;
    }

    /**
     * @notice Time-delayed proposal for withdrawing collected service fees
     * @dev Only admin can propose and accept. Requires 1-day timelock.
     * @param tokenToWithdraw Address of the token to withdraw
     * @param amountToWithdraw Amount of tokens to withdraw
     * @param proposalTime Timestamp when the proposal becomes acceptable
     */
    struct WithdrawalProposal {
        address tokenToWithdraw;
        uint256 amountToWithdraw;
        uint256 proposalTime;
    }
}

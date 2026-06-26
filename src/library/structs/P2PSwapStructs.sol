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
     * @param maxSlot Highest slot number assigned (starts at 1, increments when all slots are full)
     * @param ordersAvailable Number of currently active orders (deleted orders decrement this)
     * @param medianPrice Volume-weighted average price scaled by 1e18 (tokenB per tokenA)
     */
    struct MarketInformation {
        uint256 maxSlot;
        uint256 ordersAvailable;
        uint256 medianPrice;
    }

    /**
     * @notice Core order data stored on-chain
     * @dev Minimal storage for gas efficiency. Token addresses inferred from market ID.
     *      Deleted orders are marked by setting seller = address(0) and all amounts to 0.
     * @param seller Order creator (address(0) if order has been cancelled/filled)
     * @param offeredAmount Total amount of offeredToken originally placed in the order
     * @param requestedAmount Total amount of requestedToken expected for the full offer
     * @param amountAvailable Remaining amount of offeredToken available to be filled (decreases on partial fills)
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
     * @param marketId Market ID (bytes32 hash of token pair) containing the order
     * @param orderId Order slot ID (1-indexed)
     * @param seller Order creator address
     * @param amountA Amount of tokenA (offeredToken) in the order
     * @param amountB Amount of tokenB (requestedToken) in the order
     */
    struct OrderForGetter {
        bytes32 marketId;
        uint256 orderId;
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Fee distribution percentages for trades (basis points)
     * @dev Total must equal 10,000 (100.00%). Adjustable via time-delayed governance.
     *      Default values: seller 5000 (50%), service 4000 (40%), mateStaker 1000 (10%).
     * @param seller Basis points allocated to order seller from protocol fee
     * @param service Basis points allocated to P2PSwap service (accumulated for admin withdrawal)
     * @param mateStaker Basis points allocated to executor (staker) from protocol fee
     */
    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    /**
     * @notice Time-delayed proposal for updating fee distribution percentages
     * @dev Uses the Percentage struct for current and proposed values.
     *      Requires 1-day timelock before acceptance (TIME_TO_ACCEPT_PROPOSAL).
     * @param current Currently active percentage split
     * @param proposed Proposed percentage split awaiting acceptance
     * @param proposalTime Timestamp when the proposal becomes acceptable (block.timestamp + 1 day)
     */
    struct PercentageProposal {
        Percentage current;
        Percentage proposed;
        uint256 proposalTime;
    }

    /**
     * @notice Time-delayed proposal for withdrawing collected service fees
     * @dev Only admin can propose and accept. Requires 1-day timelock.
     *      Cannot exceed totalFeesCollected[tokenToWithdraw].
     * @param tokenToWithdraw Address of the token to withdraw
     * @param amountToWithdraw Amount of tokens to withdraw
     * @param proposalTime Timestamp when the proposal becomes acceptable (block.timestamp + 1 day)
     */
    struct WithdrawalProposal {
        address tokenToWithdraw;
        uint256 amountToWithdraw;
        uint256 proposalTime;
    }
}

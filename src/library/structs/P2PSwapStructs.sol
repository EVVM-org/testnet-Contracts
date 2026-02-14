// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title P2P Swap Data Structures
 * @author Mate labs
 * @notice Core data structures for P2PSwap.sol order book (markets, orders, fees, operation metadata)
 * @dev All operations validated via Core.sol async nonces. Payments via Core.sol.
 */

abstract contract P2PSwapStructs {
    /**
     * @notice Market metadata for token pair trading
     * @dev Tracks order slot allocation and active order count.
     * @param tokenA First token in pair
     * @param tokenB Second token in pair
     * @param maxSlot Highest slot number assigned
     * @param ordersAvailable Active order count
     */
    struct MarketInformation {
        address tokenA;
        address tokenB;
        uint256 maxSlot;
        uint256 ordersAvailable;
    }

    /**
     * @notice Core order data stored on-chain
     * @dev Minimal storage for gas efficiency. Token addresses inferred from market ID. Deleted orders: seller = address(0).
     * @param seller Order creator
     * @param amountA Amount of tokenA offered
     * @param amountB Amount of tokenB requested
     */
    struct Order {
        address seller;
        uint256 amountA;
        uint256 amountB;
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
     * @notice Metadata for makeOrder operation signature
     * @dev Hashed via P2PSwapHashUtils. Validated via Core.sol with async nonce.
     * @param nonce Async nonce
     * @param tokenA Token offered
     * @param tokenB Token requested
     * @param amountA Amount offered
     * @param amountB Amount requested
     */
    struct MetadataMakeOrder {
        uint256 nonce;
        address originExecutor;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Metadata for cancelOrder operation signature
     * @dev Hashed via P2PSwapHashUtils. Only order owner can cancel. Async nonce.
     * @param nonce Async nonce
     * @param tokenA Token A in pair
     * @param tokenB Token B in pair
     * @param orderId Order ID to cancel
     * @param signature EIP-191 signature from seller
     */
    struct MetadataCancelOrder {
        uint256 nonce;
        address originExecutor;
        address tokenA;
        address tokenB;
        uint256 orderId;
        bytes signature;
    }

    /**
     * @notice Metadata for dispatchOrder operation signature
     * @dev Hashed via P2PSwapHashUtils. Used by both proportional and fixed fee variants. Async nonce.
     * @param nonce Async nonce
     * @param tokenA Token A in pair
     * @param tokenB Token B in pair
     * @param orderId Order ID to fill
     * @param amountOfTokenBToFill Total tokenB including fees
     * @param signature EIP-191 signature from buyer
     */
    struct MetadataDispatchOrder {
        uint256 nonce;
        address originExecutor;
        address tokenA;
        address tokenB;
        uint256 orderId;
        uint256 amountOfTokenBToFill;
        bytes signature;
    }
}

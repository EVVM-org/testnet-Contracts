// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

/**
 * @title P2P Swap Hash Utilities Library
 * @author Mate labs
 * @notice Hash generation for P2PSwap.sol operations (makeOrder, cancelOrder, dispatchOrder)
 * @dev All hashes validated via Core.sol with async nonces. Three operation types supported.
 */
library P2PSwapHashUtils {
    /**
     * @notice Generates hash for makeOrder operation
     * @dev Hash: keccak256("makeOrder", tokenA, tokenB, amountA, amountB). Uses async nonce.
     * @param tokenA Token offered by seller
     * @param tokenB Token requested by seller
     * @param amountA Amount of tokenA offered
     * @param amountB Amount of tokenB requested
     * @return Hash for Core.sol validation
     */
    function hashDataForMakeOrder(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("makeOrder", tokenA, tokenB, amountA, amountB)
            );
    }

    /**
     * @notice Generates hash for cancelOrder operation
     * @dev Hash: keccak256("cancelOrder", tokenA, tokenB, orderId). Only order owner can cancel.
     * @param tokenA Token A in market pair
     * @param tokenB Token B in market pair
     * @param orderId Order ID to cancel
     * @return Hash for Core.sol validation
     */
    function hashDataForCancelOrder(
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("cancelOrder", tokenA, tokenB, orderId));
    }

    /**
     * @notice Generates hash for dispatchOrder operation
     * @dev Hash: keccak256("dispatchOrder", tokenA, tokenB, orderId). Used by both fillProportionalFee and fillFixedFee.
     * @param tokenA Token A in market pair
     * @param tokenB Token B in market pair
     * @param orderId Order ID to dispatch
     * @return Hash for Core.sol validation
     */
    function hashDataForDispatchOrder(
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("dispatchOrder", tokenA, tokenB, orderId));
    }
}

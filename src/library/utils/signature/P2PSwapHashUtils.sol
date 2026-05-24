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
     * @dev Hash: keccak256("makeOrder", offeredToken, requestedToken, offeredAmount, requestedAmount). Uses async nonce.
     * @param offeredToken Token offered by seller
     * @param requestedToken Token requested by seller
     * @param offeredAmount Amount of offeredToken offered
     * @param requestedAmount Amount of requestedToken requested
     * @return Hash for Core.sol validation
     */
    function hashDataForMakeOrder(
        address offeredToken,
        address requestedToken,
        uint256 offeredAmount,
        uint256 requestedAmount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "makeOrder",
                    offeredToken,
                    requestedToken,
                    offeredAmount,
                    requestedAmount
                )
            );
    }

    /**
     * @notice Generates hash for cancelOrder operation
     * @dev Hash: keccak256("cancelOrder", offeredToken, requestedToken, orderId). Only order owner can cancel.
     * @param offeredToken Token A in market pair
     * @param requestedToken Token B in market pair
     * @param orderId Order ID to cancel
     * @return Hash for Core.sol validation
     */
    function hashDataForCancelOrder(
        address offeredToken,
        address requestedToken,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("cancelOrder", offeredToken, requestedToken, orderId)
            );
    }

    /**
     * @notice Generates hash for dispatchOrder operation
     * @dev Hash: keccak256("dispatchOrder", offeredToken, requestedToken, orderId). 
     *      Used by both fillProportionalFee and fillFixedFee.
     * @param offeredToken Token A in market pair
     * @param requestedToken Token B in market pair
     * @param orderId Order ID to dispatch
     * @param amountOut Amount of requestedToken to receive (amountA in fillProportionalFee, 
     *                  amountB in fillFixedFee)
     * @param amountInMax Max amount of offeredToken to pay (amountB in fillProportionalFee,
     *                    amountA in fillFixedFee)
     * @return Hash for Core.sol validation
     */
    function hashDataForDispatchOrder(
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "dispatchOrder",
                    offeredToken,
                    requestedToken,
                    orderId,
                    amountOut,
                    amountInMax
                )
            );
    }
}

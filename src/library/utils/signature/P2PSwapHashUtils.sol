// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library P2PSwapHashUtils {
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

    function hashDataForCancelOrder(
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("cancelOrder", tokenA, tokenB, orderId));
    }

    function hashDataForDispatchOrder(
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("dispatchOrder", tokenA, tokenB, orderId));
    }
}

// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library P2PSwapHashUtils {
    function hashDataForMakeOrder(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("makeOrder", _tokenA, _tokenB, _amountA, _amountB)
            );
    }

    function hashDataForCancelOrder(
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("cancelOrder", _tokenA, _tokenB, _orderId));
    }

    function hashDataForDispatchOrder(
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("dispatchOrder", _tokenA, _tokenB, _orderId));
    }
}

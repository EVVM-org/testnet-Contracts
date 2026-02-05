// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;


abstract contract P2PSwapStructs {
    struct MarketInformation {
        address tokenA;
        address tokenB;
        uint256 maxSlot;
        uint256 ordersAvailable;
    }

    struct Order {
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    struct OrderForGetter {
        uint256 marketId;
        uint256 orderId;
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    struct MetadataMakeOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    struct MetadataCancelOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        bytes signature;
    }

    struct MetadataDispatchOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        uint256 amountOfTokenBToFill;
        bytes signature;
    }
}

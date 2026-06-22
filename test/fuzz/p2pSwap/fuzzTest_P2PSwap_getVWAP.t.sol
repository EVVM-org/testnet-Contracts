// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

contract fuzzTest_P2PSwap_getVWAP is Test, Constants {
    function executeBeforeSetUp() internal override {}

    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData SELLER_1 = COMMON_USER_NO_STAKER_1;
    AccountData SELLER_2 = WILDCARD_USER;
    AccountData BUYER = COMMON_USER_STAKER;

    address stableCoinAddress = makeAddr("stableCoin");

    struct OrderInput {
        uint64 offeredAmount;
        uint64 requestedAmount;
        uint64 nonce;
        uint64 noncePay;
    }

    struct TwoOrderInput {
        uint64 offeredAmount1;
        uint64 requestedAmount1;
        uint64 offeredAmount2;
        uint64 requestedAmount2;
    }

    function _addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function _makeOrder(
        AccountData memory seller,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 nonce,
        uint256 noncePay
    ) private {
        _addBalance(seller, ETHER_ADDRESS, offeredAmount);

        _executeFn_p2pSwap_makeOrder(
            FISHER_NO_STAKER,
            seller,
            ETHER_ADDRESS,
            stableCoinAddress,
            offeredAmount,
            requestedAmount,
            address(0),
            address(0),
            nonce,
            0,
            noncePay
        );
    }

    function _cancelOrder(
        AccountData memory seller,
        uint256 orderId,
        uint256 nonce,
        uint256 noncePay
    ) private {
        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
                seller,
                ETHER_ADDRESS,
                stableCoinAddress,
                orderId,
                address(0),
                address(0),
                nonce,
                0,
                noncePay
            );

        vm.startPrank(seller.Address, seller.Address);
        p2pSwap.cancelOrder(
            seller.Address,
            ETHER_ADDRESS,
            stableCoinAddress,
            orderId,
            address(0),
            address(0),
            nonce,
            signature,
            0,
            noncePay,
            signaturePay
        );
        vm.stopPrank();
    }

    function _dispatchOrder(
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 nonce,
        uint256 noncePay
    ) private {
        _addBalance(BUYER, stableCoinAddress, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
                BUYER,
                ETHER_ADDRESS,
                stableCoinAddress,
                orderId,
                amountOut,
                amountInMax,
                address(0),
                address(0),
                nonce,
                0,
                noncePay
            );

        vm.startPrank(BUYER.Address, BUYER.Address);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            ETHER_ADDRESS,
            stableCoinAddress,
            orderId,
            amountOut,
            amountInMax,
            address(0),
            address(0),
            nonce,
            signature,
            0,
            noncePay,
            signaturePay
        );
        vm.stopPrank();
    }

    function test__fuzz__getVWAP__singleOrder(
        OrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount > 0 &&
                input.offeredAmount < 1e30 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.nonce < type(uint64).max - 2000 &&
                input.noncePay > 2 &&
                input.noncePay < type(uint64).max - 2000 &&
                input.nonce != input.noncePay
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            uint256(input.nonce),
            uint256(input.noncePay)
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwap = p2pSwap.getVWAP(marketId);

        uint256 expectedVWAP = (uint256(input.requestedAmount) * 1e18) /
            uint256(input.offeredAmount);
        assertEq(vwap, expectedVWAP, "[noStaker/nPF]: VWAP should match order price");
    }

    function test__fuzz__getVWAP__afterCancelOrder(
        OrderInput memory input
    ) external {
        uint256 cancelNonce = uint256(input.nonce) + 100000;
        uint256 cancelNoncePay = uint256(input.noncePay) + 100000;

        vm.assume(
            input.offeredAmount > 0 &&
                input.offeredAmount < 1e18 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.nonce < 1e18 &&
                input.noncePay > 2 &&
                input.noncePay < 1e18 &&
                input.nonce != input.noncePay &&
                cancelNonce != input.noncePay &&
                cancelNoncePay != input.nonce
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            uint256(input.nonce),
            uint256(input.noncePay)
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwapBefore = p2pSwap.getVWAP(marketId);
        assertGt(vwapBefore, 0, "[noStaker/nPF]: VWAP should be > 0 before cancel");

        _cancelOrder(SELLER_1, 1, cancelNonce, cancelNoncePay);

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);
        assertEq(vwapAfter, 0, "[noStaker/nPF]: VWAP should be 0 after cancelling only order");
    }

    function test__fuzz__getVWAP__afterFullDispatch(
        OrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount > 0 &&
                input.offeredAmount < 1e18 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.nonce < 1e18 &&
                input.noncePay > 2 &&
                input.noncePay < 1e18 &&
                input.nonce != input.noncePay
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            uint256(input.nonce),
            uint256(input.noncePay)
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(
            uint256(input.requestedAmount)
        );

        uint256 dispatchNonce = uint256(input.nonce) + 200000;
        uint256 dispatchNoncePay = uint256(input.noncePay) + 200000;

        _dispatchOrder(
            1,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount) + feeAmount,
            dispatchNonce,
            dispatchNoncePay
        );

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);
        assertEq(
            vwapAfter,
            0,
            "[noStaker/nPF]: VWAP should be 0 after fully dispatching only order"
        );

        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);
        assertEq(
            order.amountAvailable,
            0,
            "[noStaker/nPF]: order amountAvailable should be 0 after full dispatch"
        );
    }

    function test__fuzz__getVWAP__afterPartialDispatch(
        OrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount > 1e8 &&
                input.offeredAmount < 1e18 &&
                input.requestedAmount >= 100 &&
                input.nonce > 2 &&
                input.nonce < 1e18 &&
                input.noncePay > 2 &&
                input.noncePay < 1e18 &&
                input.nonce != input.noncePay
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            uint256(input.nonce),
            uint256(input.noncePay)
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 partialAmountOut = uint256(input.offeredAmount) / 2;
        if (partialAmountOut == 0) partialAmountOut = 1;

        uint256 partialPayment = (partialAmountOut *
            uint256(input.requestedAmount)) / uint256(input.offeredAmount);
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(partialPayment);

        uint256 dispatchNonce = uint256(input.nonce) + 200000;
        uint256 dispatchNoncePay = uint256(input.noncePay) + 200000;

        _dispatchOrder(
            1,
            partialAmountOut,
            partialPayment + feeAmount,
            dispatchNonce,
            dispatchNoncePay
        );

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);

        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);
        uint256 remaining = uint256(input.offeredAmount) - partialAmountOut;
        assertEq(
            order.amountAvailable,
            remaining,
            "[noStaker/nPF]: order should have remaining amount after partial dispatch"
        );

        uint256 expectedVWAP = (uint256(input.requestedAmount) * 1e18) /
            uint256(input.offeredAmount);
        assertApproxEqRel(
            vwapAfter,
            expectedVWAP,
            5e16,
            "[noStaker/nPF]: VWAP should stay same price after partial fill"
        );
    }

    function test__fuzz__getVWAP__twoOrders(
        TwoOrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount1 > 0 &&
                input.offeredAmount1 < type(uint64).max &&
                input.requestedAmount1 > 0 &&
                input.offeredAmount2 > 0 &&
                input.offeredAmount2 < type(uint64).max &&
                input.requestedAmount2 > 0
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount1),
            uint256(input.requestedAmount1),
            1001,
            2001
        );

        _makeOrder(
            SELLER_2,
            uint256(input.offeredAmount2),
            uint256(input.requestedAmount2),
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwap = p2pSwap.getVWAP(marketId);

        uint256 totalB = (uint256(input.offeredAmount1) *
            uint256(input.requestedAmount1)) /
            uint256(input.offeredAmount1) +
            (uint256(input.offeredAmount2) *
                uint256(input.requestedAmount2)) /
            uint256(input.offeredAmount2);

        uint256 totalA = uint256(input.offeredAmount1) +
            uint256(input.offeredAmount2);

        uint256 expectedVWAP = (totalB * 1e18) / totalA;
        assertEq(
            vwap,
            expectedVWAP,
            "[noStaker/nPF]: VWAP should be weighted average of both orders"
        );
    }

    function test__fuzz__getVWAP__twoOrdersCancelOne(
        TwoOrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount1 > 0 &&
                input.offeredAmount1 < type(uint64).max &&
                input.requestedAmount1 > 0 &&
                input.offeredAmount2 > 0 &&
                input.offeredAmount2 < type(uint64).max &&
                input.requestedAmount2 > 0
        );

        _makeOrder(
            SELLER_1,
            uint256(input.offeredAmount1),
            uint256(input.requestedAmount1),
            1001,
            2001
        );

        _makeOrder(
            SELLER_2,
            uint256(input.offeredAmount2),
            uint256(input.requestedAmount2),
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        _cancelOrder(SELLER_1, 1, 3001, 4001);

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);

        uint256 expectedVWAP = (uint256(input.requestedAmount2) * 1e18) /
            uint256(input.offeredAmount2);
        assertEq(
            vwapAfter,
            expectedVWAP,
            "[noStaker/nPF]: VWAP should reflect only remaining order after cancel"
        );
    }
}

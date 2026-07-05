// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██



 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

contract unitTestCorrect_P2PSwap_getVWAP is Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    AccountData SELLER_1 = COMMON_USER_NO_STAKER_1;
    AccountData SELLER_2 = COMMON_USER_NO_STAKER_2;
    AccountData BUYER = WILDCARD_USER;

    Fisher fisher =
        Fisher({noStaker: COMMON_USER_STAKER, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function executeBeforeSetUp() internal override {}

    function _makeOrder(
        AccountData memory fisherData,
        AccountData memory seller,
        address offeredToken,
        address requestedToken,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 nonce,
        uint256 noncePay
    ) private {
        core.addBalance(seller.Address, offeredToken, offeredAmount);

        _executeFn_p2pSwap_makeOrder(
            fisherData,
            seller,
            offeredToken,
            requestedToken,
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
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 nonce,
        uint256 noncePay
    ) private {
        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
                seller,
                offeredToken,
                requestedToken,
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
            offeredToken,
            requestedToken,
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
        AccountData memory buyer,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 nonce,
        uint256 noncePay
    ) private {
        core.addBalance(buyer.Address, requestedToken, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
                buyer,
                offeredToken,
                requestedToken,
                orderId,
                amountOut,
                amountInMax,
                address(0),
                address(0),
                nonce,
                0,
                noncePay
            );

        vm.startPrank(buyer.Address, buyer.Address);
        p2pSwap.dispatchOrder(
            buyer.Address,
            offeredToken,
            requestedToken,
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

    function test__unit_correct__getVWAP__emptyMarket() external {
        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        assertEq(
            p2pSwap.getVWAP(marketId),
            0,
            "[nPF]: VWAP should be 0 for empty market"
        );
    }

    function test__unit_correct__getVWAP__singleOrder() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwap = p2pSwap.getVWAP(marketId);

        uint256 expectedVWAP = (2000 * 10 ** 6 * 1e18) / 1 ether;
        assertEq(vwap, expectedVWAP, "[nPF]: VWAP should match single order price");
    }

    function test__unit_correct__getVWAP__twoOrdersEqualAmounts() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        _makeOrder(
            fisher.noStaker,
            SELLER_2,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            3000 * 10 ** 6,
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwap = p2pSwap.getVWAP(marketId);

        uint256 totalB = (1 ether * 2000 * 10 ** 6) / 1 ether +
            (1 ether * 3000 * 10 ** 6) / 1 ether;
        uint256 expectedVWAP = (totalB * 1e18) / (1 ether + 1 ether);
        assertEq(
            vwap,
            expectedVWAP,
            "[nPF]: VWAP should be weighted average of two equal orders"
        );
    }

    function test__unit_correct__getVWAP__twoOrdersDifferentAmounts() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        _makeOrder(
            fisher.noStaker,
            SELLER_2,
            ETHER_ADDRESS,
            stableCoinAddress,
            3 ether,
            9000 * 10 ** 6,
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwap = p2pSwap.getVWAP(marketId);

        uint256 totalB = (1 ether * 2000 * 10 ** 6) / 1 ether +
            (3 ether * 9000 * 10 ** 6) / (3 ether);
        uint256 expectedVWAP = (totalB * 1e18) / (1 ether + 3 ether);
        assertEq(
            vwap,
            expectedVWAP,
            "[nPF]: VWAP should be weighted average of two different-sized orders"
        );
    }

    function test__unit_correct__getVWAP__afterCancelOrder() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        _makeOrder(
            fisher.noStaker,
            SELLER_2,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            3000 * 10 ** 6,
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 vwapBefore = p2pSwap.getVWAP(marketId);
        assertGt(vwapBefore, 0, "[nPF]: VWAP should be > 0 before cancel");

        _cancelOrder(SELLER_1, ETHER_ADDRESS, stableCoinAddress, 1, 3001, 4001);

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);

        uint256 expectedVWAP = (3000 * 10 ** 6 * 1e18) / 1 ether;
        assertEq(
            vwapAfter,
            expectedVWAP,
            "[nPF]: VWAP should reflect only remaining order after cancel"
        );
    }

    function test__unit_correct__getVWAP__afterFullDispatch() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        _makeOrder(
            fisher.noStaker,
            SELLER_2,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            3000 * 10 ** 6,
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(2000 * 10 ** 6);
        _dispatchOrder(
            BUYER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1,
            1 ether,
            2000 * 10 ** 6 + feeAmount,
            5001,
            6001
        );

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);

        uint256 expectedVWAP = (3000 * 10 ** 6 * 1e18) / 1 ether;
        assertEq(
            vwapAfter,
            expectedVWAP,
            "[nPF]: VWAP should reflect only remaining order after full dispatch"
        );
    }

    function test__unit_correct__getVWAP__afterPartialDispatch() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        uint256 partialAmount = 0.5 ether;
        uint256 partialPayment = (partialAmount * 2000 * 10 ** 6) / 1 ether;
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(partialPayment);
        _dispatchOrder(
            BUYER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1,
            partialAmount,
            partialPayment + feeAmount,
            5001,
            6001
        );

        uint256 vwapAfter = p2pSwap.getVWAP(marketId);

        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);
        assertEq(
            order.amountAvailable,
            0.5 ether,
            "[nPF]: order should have 0.5 ether remaining"
        );

        uint256 expectedVWAP = (2000 * 10 ** 6 * 1e18) / 1 ether;
        assertEq(
            vwapAfter,
            expectedVWAP,
            "[nPF]: VWAP should stay the same price after partial dispatch"
        );
    }

    function test__unit_correct__getVWAP__allOrdersCancelled() external {
        _makeOrder(
            fisher.noStaker,
            SELLER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            1001,
            2001
        );

        _makeOrder(
            fisher.noStaker,
            SELLER_2,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            3000 * 10 ** 6,
            1002,
            2002
        );

        bytes32 marketId = p2pSwap.getMarketId(
            ETHER_ADDRESS,
            stableCoinAddress
        );

        _cancelOrder(SELLER_1, ETHER_ADDRESS, stableCoinAddress, 1, 3001, 4001);
        _cancelOrder(SELLER_2, ETHER_ADDRESS, stableCoinAddress, 2, 3002, 4002);

        uint256 vwap = p2pSwap.getVWAP(marketId);
        assertEq(vwap, 0, "[nPF]: VWAP should be 0 when all orders are cancelled");
    }
}

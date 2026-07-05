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

contract unitTestCorrect_P2PSwap_dispatchOrder is Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    struct DispatchOrderInputs {
        address offeredToken;
        address requestedToken;
        uint256 orderId;
        uint256 amountOut;
        uint256 amountInMax;
        address senderExecutor;
        address originExecutor;
        uint256 nonce;
        bytes signature;
        uint256 priorityFeePay;
        uint256 noncePay;
        bytes signaturePay;
    }

    uint256 constant SELLING_PRICE = 2000 * 10 ** 6;

    AccountData BUYER = WILDCARD_USER;
    AccountData SELLER = COMMON_USER_NO_STAKER_1;
    Fisher fisher =
        Fisher({noStaker: COMMON_USER_NO_STAKER_2, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function _addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function executeBeforeSetUp() internal override {
        core.addBalance(SELLER.Address, ETHER_ADDRESS, 2 ether);
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            SELLER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            SELLING_PRICE,
            address(0),
            address(0),
            67676767676767676767676767676767676767676767676767676767676767676767,
            0,
            420420420420420420420420420420420420420420420420420420420420420420
        );
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            SELLER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            SELLING_PRICE,
            address(0),
            address(0),
            5318008,
            0,
            58008
        );
    }

    function test__unit_correct__dispatchOrder__noStaker() external {
        uint256 feeAmountNoPf = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputsNoPF = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmountNoPf,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputsNoPF.amountInMax);

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.amountOut,
            inputsNoPF.amountInMax,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.amountOut,
            inputsNoPF.amountInMax,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdNoPF = p2pSwap.getMarketId(
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken
        );

        P2PSwapStructs.Order memory orderNoPF = p2pSwap.getOrder(
            marketIdNoPF,
            1
        );

        assertEq(
            orderNoPF.seller,
            address(0),
            "[noStaker/nPF]: incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            orderNoPF.offeredAmount,
            0,
            "[noStaker/nPF]: incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            orderNoPF.requestedAmount,
            0,
            "[noStaker/nPF]: incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            orderNoPF.amountAvailable,
            0,
            "[noStaker/nPF]: incorrect order cancellation: amountAvailable should be 0"
        );

        uint256 expectedSellerBalanceNoPf = (inputsNoPF.amountInMax -
            feeAmountNoPf) +
            p2pSwap.applyBasisPoints(
                feeAmountNoPf,
                p2pSwap.getBasisPointsForReward().seller
            );

        assertEq(
            core.getBalance(SELLER.Address, inputsNoPF.requestedToken),
            expectedSellerBalanceNoPf,
            "[noStaker/nPF]: incorrect seller balance after order execution: expectedSellerBalanceNoPf"
        );

        assertEq(
            core.getBalance(BUYER.Address, inputsNoPF.offeredToken),
            1 ether,
            "[noStaker/nPF]: incorrect buyer balance after order execution: should be 1 ether"
        );

        uint256 expectedFisherBalanceNoPf = inputsNoPF.priorityFeePay +
            p2pSwap.applyBasisPoints(
                feeAmountNoPf,
                p2pSwap.getBasisPointsForReward().mateStaker
            );

        assertEq(
            core.getBalance(fisher.noStaker.Address, inputsNoPF.requestedToken),
            expectedFisherBalanceNoPf,
            "[noStaker/nPF]: incorrect fisher balance after order execution: expectedFisherBalanceNoPf"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "[noStaker/nPF]: because fisher is not a staker, their balance of principal token should not change"
        );

        ///////////////////////////////////////////////////////////////////

        uint256 feeAmountPf = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputsPf = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 2,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmountPf,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 20001,
            priorityFeePay: 0,
            noncePay: 20002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputsPf.amountInMax);

        (
            inputsPf.signature,
            inputsPf.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputsPf.offeredToken,
            inputsPf.requestedToken,
            inputsPf.orderId,
            inputsPf.amountOut,
            inputsPf.amountInMax,
            inputsPf.senderExecutor,
            inputsPf.originExecutor,
            inputsPf.nonce,
            inputsPf.priorityFeePay,
            inputsPf.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputsPf.offeredToken,
            inputsPf.requestedToken,
            inputsPf.orderId,
            inputsPf.amountOut,
            inputsPf.amountInMax,
            inputsPf.senderExecutor,
            inputsPf.originExecutor,
            inputsPf.nonce,
            inputsPf.signature,
            inputsPf.priorityFeePay,
            inputsPf.noncePay,
            inputsPf.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPf = p2pSwap.getMarketId(
            inputsPf.offeredToken,
            inputsPf.requestedToken
        );

        P2PSwapStructs.Order memory orderPf = p2pSwap.getOrder(marketIdPf, 2);

        assertEq(
            orderPf.seller,
            address(0),
            "[noStaker/PF]: incorrect order cancellation: seller should be address(0)"
        );

        assertEq(
            orderPf.offeredAmount,
            0,
            "[noStaker/PF]: incorrect order cancellation: offeredAmount should be 0"
        );

        assertEq(
            orderPf.requestedAmount,
            0,
            "[noStaker/PF]: incorrect order cancellation: requestedAmount should be 0"
        );

        assertEq(
            orderPf.amountAvailable,
            0,
            "[noStaker/PF]: incorrect order cancellation: amountAvailable should be 0"
        );

        uint256 expectedSellerBalancePf = (inputsPf.amountInMax - feeAmountPf) +
            p2pSwap.applyBasisPoints(
                feeAmountPf,
                p2pSwap.getBasisPointsForReward().seller
            );

        assertEq(
            core.getBalance(SELLER.Address, inputsPf.requestedToken),
            expectedSellerBalancePf + expectedSellerBalanceNoPf,
            "[noStaker/PF]: incorrect seller balance after order execution: expectedSellerBalancePf + expectedSellerBalanceNoPf"
        );

        assertEq(
            core.getBalance(BUYER.Address, inputsPf.offeredToken),
            2 ether,
            "[noStaker/PF]: incorrect buyer balance after order execution: should be 2 ether"
        );

        uint256 expectedFisherBalancePf = inputsPf.priorityFeePay +
            p2pSwap.applyBasisPoints(
                feeAmountPf,
                p2pSwap.getBasisPointsForReward().mateStaker
            );

        assertEq(
            core.getBalance(fisher.noStaker.Address, inputsPf.requestedToken),
            expectedFisherBalanceNoPf + expectedFisherBalancePf,
            "[noStaker/PF]: incorrect fisher balance after order execution: expectedFisherBalanceNoPf + expectedFisherBalancePf"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "[noStaker/PF]: because fisher is not a staker, their balance of principal token should not change"
        );
    }

    function test__unit_correct__dispatchOrder__staker() external {
        uint256 feeAmountNoPf = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputsNoPF = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmountNoPf,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputsNoPF.amountInMax);

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.amountOut,
            inputsNoPF.amountInMax,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.amountOut,
            inputsNoPF.amountInMax,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdNoPF = p2pSwap.getMarketId(
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken
        );

        P2PSwapStructs.Order memory orderNoPF = p2pSwap.getOrder(
            marketIdNoPF,
            1
        );

        assertEq(
            orderNoPF.seller,
            address(0),
            "[staker/nPF]: incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            orderNoPF.offeredAmount,
            0,
            "[staker/nPF]: incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            orderNoPF.requestedAmount,
            0,
            "[staker/nPF]: incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            orderNoPF.amountAvailable,
            0,
            "[staker/nPF]: incorrect order cancellation: amountAvailable should be 0"
        );

        uint256 expectedSellerBalanceNoPf = (inputsNoPF.amountInMax -
            feeAmountNoPf) +
            p2pSwap.applyBasisPoints(
                feeAmountNoPf,
                p2pSwap.getBasisPointsForReward().seller
            );

        assertEq(
            core.getBalance(SELLER.Address, inputsNoPF.requestedToken),
            expectedSellerBalanceNoPf,
            "[staker/nPF]: incorrect seller balance after order execution: expectedSellerBalanceNoPf"
        );

        assertEq(
            core.getBalance(BUYER.Address, inputsNoPF.offeredToken),
            1 ether,
            "[staker/nPF]: incorrect buyer balance after order execution: should be 1 ether"
        );

        uint256 expectedFisherBalanceNoPf = inputsNoPF.priorityFeePay +
            p2pSwap.applyBasisPoints(
                feeAmountNoPf,
                p2pSwap.getBasisPointsForReward().mateStaker
            );

        assertEq(
            core.getBalance(fisher.staker.Address, inputsNoPF.requestedToken),
            expectedFisherBalanceNoPf,
            "[staker/nPF]: incorrect fisher balance after order execution: expectedFisherBalanceNoPf"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount() * 2,
            "[staker/nPF]: because fisher is a staker, their balance of principal token should increase by the reward amount"
        );

        ///////////////////////////////////////////////////////////////////

        uint256 feeAmountPf = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputsPf = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 2,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmountPf,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 20001,
            priorityFeePay: 0,
            noncePay: 20002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputsPf.amountInMax);

        (
            inputsPf.signature,
            inputsPf.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputsPf.offeredToken,
            inputsPf.requestedToken,
            inputsPf.orderId,
            inputsPf.amountOut,
            inputsPf.amountInMax,
            inputsPf.senderExecutor,
            inputsPf.originExecutor,
            inputsPf.nonce,
            inputsPf.priorityFeePay,
            inputsPf.noncePay
        );

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputsPf.offeredToken,
            inputsPf.requestedToken,
            inputsPf.orderId,
            inputsPf.amountOut,
            inputsPf.amountInMax,
            inputsPf.senderExecutor,
            inputsPf.originExecutor,
            inputsPf.nonce,
            inputsPf.signature,
            inputsPf.priorityFeePay,
            inputsPf.noncePay,
            inputsPf.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPf = p2pSwap.getMarketId(
            inputsPf.offeredToken,
            inputsPf.requestedToken
        );

        P2PSwapStructs.Order memory orderPf = p2pSwap.getOrder(marketIdPf, 2);

        assertEq(
            orderPf.seller,
            address(0),
            "[staker/PF]: incorrect order cancellation: seller should be address(0)"
        );

        assertEq(
            orderPf.offeredAmount,
            0,
            "[staker/PF]: incorrect order cancellation: offeredAmount should be 0"
        );

        assertEq(
            orderPf.requestedAmount,
            0,
            "[staker/PF]: incorrect order cancellation: requestedAmount should be 0"
        );

        assertEq(
            orderPf.amountAvailable,
            0,
            "[staker/PF]: incorrect order cancellation: amountAvailable should be 0"
        );

        uint256 expectedSellerBalancePf = (inputsPf.amountInMax - feeAmountPf) +
            p2pSwap.applyBasisPoints(
                feeAmountPf,
                p2pSwap.getBasisPointsForReward().seller
            );

        assertEq(
            core.getBalance(SELLER.Address, inputsPf.requestedToken),
            expectedSellerBalancePf + expectedSellerBalanceNoPf,
            "[staker/PF]: incorrect seller balance after order execution: expectedSellerBalancePf + expectedSellerBalanceNoPf"
        );

        assertEq(
            core.getBalance(BUYER.Address, inputsPf.offeredToken),
            2 ether,
            "[staker/PF]: incorrect buyer balance after order execution: should be 2 ether"
        );

        uint256 expectedFisherBalancePf = inputsPf.priorityFeePay +
            p2pSwap.applyBasisPoints(
                feeAmountPf,
                p2pSwap.getBasisPointsForReward().mateStaker
            );

        assertEq(
            core.getBalance(fisher.staker.Address, inputsPf.requestedToken),
            expectedFisherBalanceNoPf + expectedFisherBalancePf,
            "[staker/PF]: incorrect fisher balance after order execution: expectedFisherBalanceNoPf + expectedFisherBalancePf"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount() * 4,
            "[staker/PF]: fisher balance of principal token should increase by the reward amount"
        );
    }
}

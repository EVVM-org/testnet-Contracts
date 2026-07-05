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

contract unitTestCorrect_P2PSwap_cancelOrder is Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    struct CancelOrderInputs {
        address offeredToken;
        address requestedToken;
        uint256 orderId;
        address senderExecutor;
        address originExecutor;
        uint256 nonce;
        bytes signature;
        uint256 priorityFeePay;
        uint256 noncePay;
        bytes signaturePay;
    }

    AccountData USER = COMMON_USER_NO_STAKER_1;
    Fisher fisher =
        Fisher({noStaker: COMMON_USER_NO_STAKER_2, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function executeBeforeSetUp() internal override {
        core.addBalance(USER.Address, ETHER_ADDRESS, 2 ether);
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            address(0),
            address(0),
            67676767676767676767676767676767676767676767676767676767676767676767,
            0,
            420420420420420420420420420420420420420420420420420420420420420420
        );
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            address(0),
            address(0),
            5318008,
            0,
            58008
        );
    }

    function test__unit_correct__cancelOrder__noStaker() external {
        CancelOrderInputs memory inputsNoPF = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
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

        assertEq(
            core.getBalance(USER.Address, inputsNoPF.offeredToken),
            1 ether,
            "[noStaker/nPF]: incorrect balance after cancellation: user should have original offered amount back"
        );

        ///////////////////////////////////////////////////////////////////

        CancelOrderInputs memory inputsPF = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 2,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 333,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 555,
            signaturePay: hex""
        });

        (
            inputsPF.signature,
            inputsPF.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.orderId,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.priorityFeePay,
            inputsPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.orderId,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.signature,
            inputsPF.priorityFeePay,
            inputsPF.noncePay,
            inputsPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPF = p2pSwap.getMarketId(
            inputsPF.offeredToken,
            inputsPF.requestedToken
        );

        P2PSwapStructs.Order memory orderPF = p2pSwap.getOrder(marketIdPF, 2);

        assertEq(
            orderPF.seller,
            address(0),
            "[noStaker/PF]: incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            orderPF.offeredAmount,
            0,
            "[noStaker/PF]: incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            orderPF.requestedAmount,
            0,
            "[noStaker/PF]: incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            orderPF.amountAvailable,
            0,
            "[noStaker/PF]: incorrect order cancellation: amountAvailable should be 0"
        );

        assertEq(
            core.getBalance(USER.Address, inputsPF.offeredToken),
            2 ether,
            "[noStaker/PF]: incorrect balance after cancellation: user should have original offered amount back"
        );
    }

    function test__unit_correct__cancelOrder__staker() external {
        CancelOrderInputs memory inputsNoPF = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.orderId,
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

        assertEq(
            core.getBalance(USER.Address, inputsNoPF.offeredToken),
            1 ether,
            "[staker/nPF]: incorrect balance after cancellation: user should have original offered amount back"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            inputsNoPF.priorityFeePay + core.getRewardAmount(),
            "[staker/nPF]: incorrect staker reward after cancellation: staker should receive priority fee pay and reward amount"
        );

        ///////////////////////////////////////////////////////////////////

        CancelOrderInputs memory inputsPF = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 2,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 333,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 555,
            signaturePay: hex""
        });

        (
            inputsPF.signature,
            inputsPF.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.orderId,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.priorityFeePay,
            inputsPF.noncePay
        );

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.orderId,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.signature,
            inputsPF.priorityFeePay,
            inputsPF.noncePay,
            inputsPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPF = p2pSwap.getMarketId(
            inputsPF.offeredToken,
            inputsPF.requestedToken
        );

        P2PSwapStructs.Order memory orderPF = p2pSwap.getOrder(marketIdPF, 2);

        assertEq(
            orderPF.seller,
            address(0),
            "[staker/PF]: incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            orderPF.offeredAmount,
            0,
            "[staker/PF]: incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            orderPF.requestedAmount,
            0,
            "[staker/PF]: incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            orderPF.amountAvailable,
            0,
            "[staker/PF]: incorrect order cancellation: amountAvailable should be 0"
        );

        assertEq(
            core.getBalance(USER.Address, inputsPF.offeredToken),
            2 ether,
            "[staker/PF]: incorrect balance after cancellation: user should have original offered amount back"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            inputsNoPF.priorityFeePay + inputsPF.priorityFeePay + core.getRewardAmount() * 2,
            "[staker/PF]: incorrect staker reward after cancellation: staker should receive priority fee pay and reward amount"
        );
    }
}
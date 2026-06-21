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

contract fuzzTest_P2PSwap_cancelOrder is Test, Constants {
    function executeBeforeSetUp() internal override {}

    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    address stableCoinAddress = makeAddr("stableCoin");

    struct CancelOrderInput {
        uint64 offeredAmount;
        uint64 requestedAmount;
        uint32 priorityFeePay;
        uint64 nonce;
        uint64 noncePay;
        bool isOfferedEther;
        bool isRequestedStable;
    }

    function _addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function test__fuzz__cancelOrder__noStaker(
        CancelOrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount > 0 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.noncePay > 2 &&
                input.nonce != input.noncePay &&
                !(input.isOfferedEther && input.isRequestedStable == false)
        );

        address offeredToken = input.isOfferedEther
            ? ETHER_ADDRESS
            : stableCoinAddress;
        address requestedToken = input.isRequestedStable
            ? stableCoinAddress
            : PRINCIPAL_TOKEN_ADDRESS;

        if (offeredToken == requestedToken) {
            requestedToken = input.isOfferedEther
                ? stableCoinAddress
                : PRINCIPAL_TOKEN_ADDRESS;
        }

        _addBalance(USER, offeredToken, uint256(input.offeredAmount));
        _executeFn_p2pSwap_makeOrder(
            WILDCARD_USER,
            USER,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            0,
            uint256(input.noncePay)
        );

        uint256 cancelNonce = uint256(input.nonce) + 1000;
        uint256 cancelNoncePay = uint256(input.noncePay) + 1000;

        (
            bytes memory signatureCancel,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
                USER,
                offeredToken,
                requestedToken,
                1,
                address(0),
                address(0),
                cancelNonce,
                uint256(input.priorityFeePay),
                cancelNoncePay
            );

        _addBalance(
            USER,
            PRINCIPAL_TOKEN_ADDRESS,
            uint256(input.priorityFeePay)
        );
        vm.startPrank(FISHER_NO_STAKER.Address, FISHER_NO_STAKER.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            offeredToken,
            requestedToken,
            1,
            address(0),
            address(0),
            cancelNonce,
            signatureCancel,
            uint256(input.priorityFeePay),
            cancelNoncePay,
            signaturePay
        );
        vm.stopPrank();

        bytes32 marketId = p2pSwap.getMarketId(offeredToken, requestedToken);
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);

        assertEq(
            order.seller,
            address(0),
            "[NoStaker] incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            order.offeredAmount,
            0,
            "[NoStaker] incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            order.requestedAmount,
            0,
            "[NoStaker] incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            order.amountAvailable,
            0,
            "[NoStaker] incorrect order cancellation: amountAvailable should be 0"
        );

        assertEq(
            core.getBalance(USER.Address, offeredToken),
            uint256(input.offeredAmount),
            "[NoStaker] incorrect balance after cancellation: user should have original offered amount back"
        );

        assertEq(
            core.getBalance(address(p2pSwap), offeredToken),
            0,
            "[NoStaker] incorrect p2pSwap balance after cancellation"
        );
    }

    function test__fuzz__cancelOrder__staker(
        CancelOrderInput memory input
    ) external {
        vm.assume(
            input.offeredAmount > 0 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.noncePay > 2 &&
                input.nonce != input.noncePay &&
                !(input.isOfferedEther && input.isRequestedStable == false)
        );

        address offeredToken = input.isOfferedEther
            ? ETHER_ADDRESS
            : stableCoinAddress;
        address requestedToken = input.isRequestedStable
            ? stableCoinAddress
            : PRINCIPAL_TOKEN_ADDRESS;

        if (offeredToken == requestedToken) {
            requestedToken = input.isOfferedEther
                ? stableCoinAddress
                : PRINCIPAL_TOKEN_ADDRESS;
        }

        _addBalance(USER, offeredToken, uint256(input.offeredAmount));
        _executeFn_p2pSwap_makeOrder(
            WILDCARD_USER,
            USER,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            0,
            uint256(input.noncePay)
        );

        uint256 cancelNonce = uint256(input.nonce) + 1000;
        uint256 cancelNoncePay = uint256(input.noncePay) + 1000;

        (
            bytes memory signatureCancel,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
                USER,
                offeredToken,
                requestedToken,
                1,
                address(0),
                address(0),
                cancelNonce,
                uint256(input.priorityFeePay),
                cancelNoncePay
            );

        _addBalance(
            USER,
            PRINCIPAL_TOKEN_ADDRESS,
            uint256(input.priorityFeePay)
        );
        vm.startPrank(FISHER_STAKER.Address, FISHER_STAKER.Address);
        p2pSwap.cancelOrder(
            USER.Address,
            offeredToken,
            requestedToken,
            1,
            address(0),
            address(0),
            cancelNonce,
            signatureCancel,
            uint256(input.priorityFeePay),
            cancelNoncePay,
            signaturePay
        );
        vm.stopPrank();

        bytes32 marketId = p2pSwap.getMarketId(offeredToken, requestedToken);
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);

        assertEq(
            order.seller,
            address(0),
            "[Staker] incorrect order cancellation: seller should be address(0)"
        );
        assertEq(
            order.offeredAmount,
            0,
            "[Staker] incorrect order cancellation: offeredAmount should be 0"
        );
        assertEq(
            order.requestedAmount,
            0,
            "[Staker] incorrect order cancellation: requestedAmount should be 0"
        );
        assertEq(
            order.amountAvailable,
            0,
            "[Staker] incorrect order cancellation: amountAvailable should be 0"
        );

        assertEq(
            core.getBalance(USER.Address, offeredToken),
            uint256(input.offeredAmount),
            "[Staker] incorrect balance after cancellation: user should have original offered amount back"
        );

        assertEq(
            core.getBalance(address(p2pSwap), offeredToken),
            0,
            "[Staker] incorrect p2pSwap balance after cancellation"
        );

        uint256 expectedReward = input.priorityFeePay > 0
            ? core.getRewardAmount() + uint256(input.priorityFeePay)
            : core.getRewardAmount();
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            expectedReward,
            "[Staker] incorrect fisher reward balance"
        );
    }
}

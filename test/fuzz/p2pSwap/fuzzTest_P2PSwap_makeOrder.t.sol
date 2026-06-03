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

contract fuzzTest_P2PSwap_makeOrder is Test, Constants {
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    address stableCoinAddress = makeAddr("stableCoin");

    struct MakeOrderInput {
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

    function test__fuzz__makeOrder__noStaker(
        MakeOrderInput memory input
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

        // Prevent same token pair
        if (offeredToken == requestedToken) {
            requestedToken = input.isOfferedEther
                ? stableCoinAddress
                : PRINCIPAL_TOKEN_ADDRESS;
        }

        _addBalance(
            USER,
            offeredToken,
            uint256(input.offeredAmount) + uint256(input.priorityFeePay)
        );

        (
            bytes memory signatureMakeOrder,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            USER,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            uint256(input.priorityFeePay),
            uint256(input.noncePay)
        );

        vm.startPrank(FISHER_NO_STAKER.Address, FISHER_NO_STAKER.Address);
        p2pSwap.makeOrder(
            USER.Address,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            signatureMakeOrder,
            uint256(input.priorityFeePay),
            uint256(input.noncePay),
            signaturePay
        );
        vm.stopPrank();

        bytes32 marketId = p2pSwap.getMarketId(offeredToken, requestedToken);
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);

        assertEq(
            order.seller,
            USER.Address,
            "[NoStaker] incorrect seller in order"
        );
        assertEq(
            order.offeredAmount,
            uint256(input.offeredAmount),
            "[NoStaker] incorrect offeredAmount in order"
        );
        assertEq(
            order.requestedAmount,
            uint256(input.requestedAmount),
            "[NoStaker] incorrect requestedAmount in order"
        );
        assertEq(
            order.amountAvailable,
            uint256(input.offeredAmount),
            "[NoStaker] incorrect amountAvailable in order"
        );

        assertEq(
            core.getBalance(USER.Address, offeredToken),
            0,
            "[NoStaker] incorrect user balance after makeOrder"
        );

        // When executor is not staker, priorityFee stays in p2pSwap as collected fees
        assertEq(
            core.getBalance(address(p2pSwap), offeredToken),
            uint256(input.offeredAmount) + uint256(input.priorityFeePay),
            "[NoStaker] incorrect p2pSwap balance after makeOrder"
        );

        // No staker = no reward
        assertEq(
            core.getBalance(
                FISHER_NO_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "[NoStaker] incorrect fisher reward balance"
        );
    }

    function test__fuzz__makeOrder__staker(
        MakeOrderInput memory input
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

        // Prevent same token pair
        if (offeredToken == requestedToken) {
            requestedToken = input.isOfferedEther
                ? stableCoinAddress
                : PRINCIPAL_TOKEN_ADDRESS;
        }

        _addBalance(
            USER,
            offeredToken,
            uint256(input.offeredAmount) + uint256(input.priorityFeePay)
        );

        (
            bytes memory signatureMakeOrder,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            USER,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            uint256(input.priorityFeePay),
            uint256(input.noncePay)
        );

        vm.startPrank(FISHER_STAKER.Address, FISHER_STAKER.Address);
        p2pSwap.makeOrder(
            USER.Address,
            offeredToken,
            requestedToken,
            uint256(input.offeredAmount),
            uint256(input.requestedAmount),
            address(0),
            address(0),
            uint256(input.nonce),
            signatureMakeOrder,
            uint256(input.priorityFeePay),
            uint256(input.noncePay),
            signaturePay
        );
        vm.stopPrank();

        bytes32 marketId = p2pSwap.getMarketId(offeredToken, requestedToken);
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);

        assertEq(
            order.seller,
            USER.Address,
            "[Staker] incorrect seller in order"
        );
        assertEq(
            order.offeredAmount,
            uint256(input.offeredAmount),
            "[Staker] incorrect offeredAmount in order"
        );
        assertEq(
            order.requestedAmount,
            uint256(input.requestedAmount),
            "[Staker] incorrect requestedAmount in order"
        );
        assertEq(
            order.amountAvailable,
            uint256(input.offeredAmount),
            "[Staker] incorrect amountAvailable in order"
        );

        assertEq(
            core.getBalance(USER.Address, offeredToken),
            0,
            "[Staker] incorrect user balance after makeOrder"
        );

        // When executor is staker + priorityFee > 0, staker receives priorityFee
        // so p2pSwap only keeps offeredAmount
        assertEq(
            core.getBalance(address(p2pSwap), offeredToken),
            uint256(input.offeredAmount),
            "[Staker] incorrect p2pSwap balance after makeOrder"
        );

        // Reward multiplier: 2 if priorityFee > 0, otherwise 1
        uint256 expectedReward = input.priorityFeePay > 0
            ? core.getRewardAmount() * 2
            : core.getRewardAmount();
        assertEq(
            core.getBalance(
                FISHER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            expectedReward,
            "[Staker] incorrect fisher reward balance"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, offeredToken),
            uint256(input.priorityFeePay),
            "[Staker] incorrect fisher priorityFee balance"
        );
    }
}

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

contract fuzzTest_P2PSwap_dispatchOrder is Test, Constants {
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData BUYER = WILDCARD_USER;
    AccountData SELLER = COMMON_USER_NO_STAKER_1;

    address stableCoinAddress = makeAddr("stableCoin");

    struct DispatchOrderInput {
        uint64 offeredAmount;
        uint64 requestedAmount;
        uint32 priorityFeePay;
        uint64 nonce;
        uint64 noncePay;
        uint64 nonceDispatch;
        uint64 noncePayDispatch;
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

    function _createOrderAndDispatch(
        AccountData memory fisherAccount,
        DispatchOrderInput memory input,
        bool isStaker,
        string memory tag
    ) private {
        vm.assume(
            input.offeredAmount > 0 &&
                input.requestedAmount > 0 &&
                input.nonce > 2 &&
                input.noncePay > 2 &&
                input.nonceDispatch > 2 &&
                input.noncePayDispatch > 2 &&
                input.nonce != input.noncePay &&
                input.nonceDispatch != input.noncePayDispatch &&
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

        _addBalance(
            SELLER,
            offeredToken,
            uint256(input.offeredAmount) + uint256(input.priorityFeePay)
        );

        _executeFn_p2pSwap_makeOrder(
            fisherAccount,
            SELLER,
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

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(
            uint256(input.requestedAmount)
        );
        uint256 amountInMax = uint256(input.requestedAmount) + feeAmount;

        _addBalance(BUYER, requestedToken, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            offeredToken,
            requestedToken,
            1,
            uint256(input.offeredAmount),
            amountInMax,
            address(0),
            address(0),
            uint256(input.nonceDispatch),
            0,
            uint256(input.noncePayDispatch)
        );

        vm.startPrank(
            fisherAccount.Address,
            fisherAccount.Address
        );
        p2pSwap.dispatchOrder(
            BUYER.Address,
            offeredToken,
            requestedToken,
            1,
            uint256(input.offeredAmount),
            amountInMax,
            address(0),
            address(0),
            uint256(input.nonceDispatch),
            signature,
            0,
            uint256(input.noncePayDispatch),
            signaturePay
        );
        vm.stopPrank();

        bytes32 marketId = p2pSwap.getMarketId(offeredToken, requestedToken);
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(marketId, 1);

        assertEq(
            order.seller,
            address(0),
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect order dispatch: seller should be address(0)"
                )
            )
        );
        assertEq(
            order.offeredAmount,
            0,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect order dispatch: offeredAmount should be 0"
                )
            )
        );
        assertEq(
            order.requestedAmount,
            0,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect order dispatch: requestedAmount should be 0"
                )
            )
        );
        assertEq(
            order.amountAvailable,
            0,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect order dispatch: amountAvailable should be 0"
                )
            )
        );

        uint256 expectedSellerBalance = (amountInMax - feeAmount) +
            p2pSwap.applyBasisPoints(
                feeAmount,
                p2pSwap.getBasisPointsForReward().seller
            );

        assertEq(
            core.getBalance(SELLER.Address, requestedToken),
            expectedSellerBalance,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect seller balance after order execution"
                )
            )
        );

        assertEq(
            core.getBalance(BUYER.Address, offeredToken),
            uint256(input.offeredAmount),
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect buyer balance after order execution"
                )
            )
        );

        uint256 expectedFisherBalance = p2pSwap.applyBasisPoints(
            feeAmount,
            p2pSwap.getBasisPointsForReward().mateStaker
        );

        uint256 stakingRewards = isStaker ? core.getRewardAmount() * 3 : 0;

        assertEq(
            core.getBalance(fisherAccount.Address, requestedToken),
            requestedToken == PRINCIPAL_TOKEN_ADDRESS
                ? expectedFisherBalance + stakingRewards
                : expectedFisherBalance,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect fisher balance after order execution"
                )
            )
        );

        uint256 expectedPrincipalBalance = requestedToken == PRINCIPAL_TOKEN_ADDRESS
            ? expectedFisherBalance + stakingRewards
            : stakingRewards;

        assertEq(
            core.getBalance(fisherAccount.Address, PRINCIPAL_TOKEN_ADDRESS),
            expectedPrincipalBalance,
            string(
                abi.encodePacked(
                    "[",
                    tag,
                    "] incorrect fisher principal token balance"
                )
            )
        );
    }

    function test__fuzz__dispatchOrder__noStaker(
        DispatchOrderInput memory input
    ) external {
        _createOrderAndDispatch(FISHER_NO_STAKER, input, false, "NoStaker");
    }

    function test__fuzz__dispatchOrder__staker(
        DispatchOrderInput memory input
    ) external {
        _createOrderAndDispatch(FISHER_STAKER, input, true, "Staker");
    }
}

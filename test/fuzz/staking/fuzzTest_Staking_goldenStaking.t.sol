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


 * @title fuzz test for staking function correct behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_Staking_goldenStaking is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        uint256 totalAmount = giveMateToExecute(GOLDEN_STAKER.Address, 10);

        bytes memory signatureEVVM = makePaySignature(totalAmount);

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(true, 10, signatureEVVM);

        vm.stopPrank();
    }

    function giveMateToExecute(
        address user,
        uint256 stakingAmount
    ) private returns (uint256 totalAmount) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking() * stakingAmount
        );

        totalAmount = staking.priceOfStaking() * stakingAmount;
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    function makePaySignature(
        uint256 amount
    ) private view returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            GOLDEN_STAKER.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amount,
                0,
                evvm.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
                false,
                address(staking)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    struct GoldenStakingFuzzTestInput {
        bool isStaking;
        uint8 amount;
    }

    function test__fuzz__goldenStaking__staking(
        GoldenStakingFuzzTestInput[10] memory input
    ) external {
        uint256 totalAmount;
        bytes memory signatureEVVM;
        uint256 amountBefore;
        uint256 stakingFullAmountBefore;
        uint256 totalStakedBefore;

        for (uint256 i = 0; i < input.length; i++) {
            console2.log("isStaking", input[i].isStaking);
            console2.log("amount", input[i].amount);

            totalStakedBefore = staking.getUserAmountStaked(
                GOLDEN_STAKER.Address
            );

            amountBefore = evvm.getBalance(
                GOLDEN_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            );
            if (input[i].isStaking) {
                // staking
                if (staking.getUserAmountStaked(GOLDEN_STAKER.Address) == 0) {
                    vm.warp(
                        staking.getTimeToUserUnlockStakingTime(
                            GOLDEN_STAKER.Address
                        )
                    );
                }

                totalAmount = giveMateToExecute(
                    GOLDEN_STAKER.Address,
                    input[i].amount
                );

                signatureEVVM = makePaySignature(totalAmount);

                vm.startPrank(GOLDEN_STAKER.Address);

                staking.goldenStaking(
                    input[i].isStaking,
                    input[i].amount,
                    signatureEVVM
                );

                vm.stopPrank();

                assert(evvm.isAddressStaker(GOLDEN_STAKER.Address));
            } else {
                // unstaking
                if (
                    input[i].amount >=
                    staking.getUserAmountStaked(GOLDEN_STAKER.Address)
                ) {
                    vm.warp(
                        staking.getTimeToUserUnlockFullUnstakingTime(
                            GOLDEN_STAKER.Address
                        )
                    );

                    stakingFullAmountBefore = staking.getUserAmountStaked(
                        GOLDEN_STAKER.Address
                    );
                    vm.startPrank(GOLDEN_STAKER.Address);

                    staking.goldenStaking(
                        input[i].isStaking,
                        staking.getUserAmountStaked(GOLDEN_STAKER.Address),
                        signatureEVVM
                    );

                    vm.stopPrank();

                    assert(!evvm.isAddressStaker(GOLDEN_STAKER.Address));
                } else {
                    vm.startPrank(GOLDEN_STAKER.Address);

                    staking.goldenStaking(
                        input[i].isStaking,
                        input[i].amount,
                        signatureEVVM
                    );

                    vm.stopPrank();
                }
            }

            Staking.HistoryMetadata memory history = staking
                .getAddressHistoryByIndex(GOLDEN_STAKER.Address, i + 1);

            assertEq(
                evvm.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
                amountBefore +
                    calculateRewardPerExecution(
                        evvm.isAddressStaker(GOLDEN_STAKER.Address) ? 1 : 0
                    ) +
                    (
                        input[i].isStaking
                            ? 0
                            : (
                                staking.getUserAmountStaked(
                                    GOLDEN_STAKER.Address
                                ) == 0
                                    ? staking.priceOfStaking() *
                                        stakingFullAmountBefore
                                    : staking.priceOfStaking() * input[i].amount
                            )
                    )
            );

            assertEq(history.timestamp, block.timestamp);
            assert(
                history.transactionType ==
                    (
                        input[i].isStaking
                            ? DEPOSIT_HISTORY_SMATE_IDENTIFIER
                            : WITHDRAW_HISTORY_SMATE_IDENTIFIER
                    )
            );
            assertEq(
                history.amount,
                (
                    input[i].isStaking
                        ? input[i].amount
                        : (
                            staking.getUserAmountStaked(
                                GOLDEN_STAKER.Address
                            ) == 0
                                ? stakingFullAmountBefore
                                : input[i].amount
                        )
                )
            );
            if (input[i].isStaking) {
                assertEq(
                    history.totalStaked,
                    totalStakedBefore + input[i].amount
                );
            } else {
                assertEq(
                    history.totalStaked,
                    totalStakedBefore -
                        (
                            staking.getUserAmountStaked(
                                GOLDEN_STAKER.Address
                            ) == 0
                                ? stakingFullAmountBefore
                                : input[i].amount
                        )
                );
            }
        }
    }
}

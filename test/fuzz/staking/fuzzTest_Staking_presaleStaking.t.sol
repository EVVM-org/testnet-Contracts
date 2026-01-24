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

contract fuzzTest_Staking_presaleStaking is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        giveMateToExecute(COMMON_USER_NO_STAKER_1, true, 0);

        (
            bytes memory signatureEVVM,
            bytes memory signatureStaking
        ) = makePresaleStakingSignature(
                COMMON_USER_NO_STAKER_1,
                true,
                0,
                0,
                0,
                false
            );

        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            0,
            signatureStaking,
            0,
            0,
            false,
            signatureEVVM
        );
    }

    function giveMateToExecute(
        AccountData memory user,
        bool isStaking,
        uint256 priorityFee
    ) private returns (uint256 totalOfMate, uint256 totalOfPriorityFee) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (isStaking ? (staking.priceOfStaking() * 1) : 0) + priorityFee
        );

        totalOfMate = (isStaking ? (staking.priceOfStaking() * 1) : 0);
        totalOfPriorityFee = priorityFee;
    }

    function makePresaleStakingSignature(
        AccountData memory user,
        bool isStaking,
        uint256 priorityFee,
        uint256 nonceSmate,
        uint256 nonceEVVM,
        bool priorityEVVM
    )
        private
        view
        returns (bytes memory signatureEVVM, bytes memory signatureStaking)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (isStaking) {
            (v, r, s) = vm.sign(
                user.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    staking.priceOfStaking() * 1,
                    priorityFee,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        } else {
            (v, r, s) = vm.sign(
                user.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                    evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    priorityFee,
                    0,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        }

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                isStaking,
                1,
                nonceSmate
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    struct PresaleStakingFuzzTestInput {
        bool isStaking;
        bool usingStaker;
        uint144 nonceStaking;
        uint144 nonceEVVM;
        bool priorityEVVM;
        bool givePriorityFee;
        uint16 priorityFeeAmountEVVM;
    }

    function test__fuzz__presaleStaking_AsyncExecution(
        PresaleStakingFuzzTestInput[20] memory input
    ) external {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        Staking.HistoryMetadata memory history;
        uint256 amountBeforeFisher;
        uint256 amountBeforeUser;
        uint256 totalStakedBefore;
        AccountData memory FISHER;

        uint256 incorrectTxCount = 0;

        for (uint256 i = 0; i < input.length; i++) {
            if (
                staking.getIfUsedAsyncNonce(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].nonceStaking
                )
            ) {
                incorrectTxCount++;
                continue;
            }

            if (
                evvm.getIfUsedAsyncNonce(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].nonceEVVM
                )
            ) {
                incorrectTxCount++;
                continue;
            }

            FISHER = input[i].usingStaker
                ? COMMON_USER_STAKER
                : COMMON_USER_NO_STAKER_2;

            amountBeforeFisher = evvm.getBalance(
                FISHER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            );

            amountBeforeUser = evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            );

            totalStakedBefore = staking.getUserAmountStaked(
                COMMON_USER_NO_STAKER_1.Address
            );

            if (input[i].isStaking) {
                // staking
                if (
                    staking.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) == 2
                ) {
                    incorrectTxCount++;
                    continue;
                }
                if (
                    staking.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) == 0
                ) {
                    vm.warp(
                        staking.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }

                giveMateToExecute(
                    COMMON_USER_NO_STAKER_1,
                    true,
                    (
                        input[i].givePriorityFee
                            ? uint256(input[i].priorityFeeAmountEVVM)
                            : 0
                    )
                );

                (signatureEVVM, signatureStaking) = makePresaleStakingSignature(
                    COMMON_USER_NO_STAKER_1,
                    input[i].isStaking,
                    (
                        input[i].givePriorityFee
                            ? uint256(input[i].priorityFeeAmountEVVM)
                            : 0
                    ),
                    input[i].nonceStaking,
                    (
                        input[i].priorityEVVM
                            ? input[i].nonceEVVM
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                    input[i].priorityEVVM
                );

                vm.startPrank(FISHER.Address);
                staking.presaleStaking(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].isStaking,
                    input[i].nonceStaking,
                    signatureStaking,
                    (
                        input[i].givePriorityFee
                            ? uint256(input[i].priorityFeeAmountEVVM)
                            : 0
                    ),
                    (
                        input[i].priorityEVVM
                            ? input[i].nonceEVVM
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                    input[i].priorityEVVM,
                    signatureEVVM
                );
                vm.stopPrank();
            } else {
                // unstaking
                if (
                    staking.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) == 0
                ) {
                    incorrectTxCount++;
                    continue;
                }

                if (
                    staking.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    ) == 1
                ) {
                    vm.warp(
                        staking.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }

                if (input[i].givePriorityFee) {
                    giveMateToExecute(
                        COMMON_USER_NO_STAKER_1,
                        false,
                        uint256(input[i].priorityFeeAmountEVVM)
                    );
                }

                (signatureEVVM, signatureStaking) = makePresaleStakingSignature(
                    COMMON_USER_NO_STAKER_1,
                    input[i].isStaking,
                    (
                        input[i].givePriorityFee
                            ? uint256(input[i].priorityFeeAmountEVVM)
                            : 0
                    ),
                    input[i].nonceStaking,
                    (
                        input[i].priorityEVVM
                            ? input[i].nonceEVVM
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                    input[i].priorityEVVM
                );

                vm.startPrank(FISHER.Address);
                staking.presaleStaking(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].isStaking,
                    input[i].nonceStaking,
                    signatureStaking,
                    (
                        input[i].givePriorityFee
                            ? uint256(input[i].priorityFeeAmountEVVM)
                            : 0
                    ),
                    (
                        input[i].priorityEVVM
                            ? input[i].nonceEVVM
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                    input[i].priorityEVVM,
                    signatureEVVM
                );
                vm.stopPrank();
            }

            history = staking.getAddressHistoryByIndex(
                COMMON_USER_NO_STAKER_1.Address,
                (i + 1) - incorrectTxCount
            );

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    PRINCIPAL_TOKEN_ADDRESS
                ),
                amountBeforeUser +
                    (input[i].isStaking ? 0 : staking.priceOfStaking() * 1)
            );

            if (FISHER.Address == COMMON_USER_STAKER.Address) {
                assertEq(
                    evvm.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher +
                        calculateRewardPerExecution(1) +
                        (
                            input[i].givePriorityFee
                                ? uint256(input[i].priorityFeeAmountEVVM)
                                : 0
                        )
                );
            } else {
                assertEq(
                    evvm.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher
                );
            }

            assertEq(history.timestamp, block.timestamp);
            assert(
                history.transactionType ==
                    (
                        input[i].isStaking
                            ? DEPOSIT_HISTORY_SMATE_IDENTIFIER
                            : WITHDRAW_HISTORY_SMATE_IDENTIFIER
                    )
            );

            assertEq(history.amount, 1);

            if (input[i].isStaking) {
                assertEq(history.totalStaked, totalStakedBefore + 1);
            } else {
                assertEq(history.totalStaked, totalStakedBefore - 1);
            }
        }
    }
}

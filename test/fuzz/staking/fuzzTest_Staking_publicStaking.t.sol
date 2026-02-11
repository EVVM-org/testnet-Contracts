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
import "@evvm/testnet-contracts/library/structs/StakingStructs.sol";

contract fuzzTest_Staking_publicStaking is Test, Constants {
    function executeBeforeSetUp() internal override {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 10, 0);

        _executeFn_staking_publicStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            10,
            0,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            COMMON_USER_NO_STAKER_1
        );
    }

    function _addBalance(
        address user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 totalOfMate, uint256 totalOfPriorityFee) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount) + priorityFee
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
        totalOfPriorityFee = priorityFee;
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    struct PublicStakingFuzzTestInput {
        bool isStaking;
        bool usingStaker;
        uint8 stakingAmount;
        uint144 nonceStaking;
        uint144 nonceEVVM;
        bool isAsyncExecEvvm;
        uint16 priorityFeeAmountEVVM;
    }

    function test__fuzz__publicStaking(
        PublicStakingFuzzTestInput[20] memory input
    ) external {
        StakingStructs.HistoryMetadata memory history;
        uint256 amountBeforeFisher;
        uint256 amountBeforeUser;
        uint256 totalStakedBefore;
        AccountData memory FISHER;
        uint256 incorrectTxCount = 0;
        uint256 stakingFullAmountBefore;

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

            if (input[i].isAsyncExecEvvm) {
                
                if (input[i].nonceStaking == input[i].nonceEVVM) {
                    incorrectTxCount++;
                    continue;
                }
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
                    ) == 0
                ) {
                    vm.warp(
                        staking.getTimeToUserUnlockStakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );
                }

                _addBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].stakingAmount,
                    input[i].priorityFeeAmountEVVM
                );

                _executeFn_staking_publicStaking(
                    COMMON_USER_NO_STAKER_1,
                    input[i].isStaking,
                    input[i].stakingAmount,
                    input[i].nonceStaking,
                    input[i].priorityFeeAmountEVVM,
                    (
                        input[i].isAsyncExecEvvm
                            ? input[i].nonceEVVM
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                    input[i].isAsyncExecEvvm,
                    FISHER
                );
            } else {
                // unstaking
                if (
                    input[i].stakingAmount >=
                    staking.getUserAmountStaked(COMMON_USER_NO_STAKER_1.Address)
                ) {
                    vm.warp(
                        staking.getTimeToUserUnlockFullUnstakingTime(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                    );

                    stakingFullAmountBefore = staking.getUserAmountStaked(
                        COMMON_USER_NO_STAKER_1.Address
                    );

                    _addBalance(
                        COMMON_USER_NO_STAKER_1.Address,
                        0,
                        input[i].priorityFeeAmountEVVM
                    );

                    _executeFn_staking_publicStaking(
                        COMMON_USER_NO_STAKER_1,
                        input[i].isStaking,
                        stakingFullAmountBefore,
                        input[i].nonceStaking,
                        input[i].priorityFeeAmountEVVM,
                        (
                            input[i].isAsyncExecEvvm
                                ? input[i].nonceEVVM
                                : evvm.getNextCurrentSyncNonce(
                                    COMMON_USER_NO_STAKER_1.Address
                                )
                        ),
                        input[i].isAsyncExecEvvm,
                        FISHER
                    );
                } else {
                    _addBalance(
                        COMMON_USER_NO_STAKER_1.Address,
                        0,
                        input[i].priorityFeeAmountEVVM
                    );

                    _executeFn_staking_publicStaking(
                        COMMON_USER_NO_STAKER_1,
                        input[i].isStaking,
                        input[i].stakingAmount,
                        input[i].nonceStaking,
                        input[i].priorityFeeAmountEVVM,
                        (
                            input[i].isAsyncExecEvvm
                                ? input[i].nonceEVVM
                                : evvm.getNextCurrentSyncNonce(
                                    COMMON_USER_NO_STAKER_1.Address
                                )
                        ),
                        input[i].isAsyncExecEvvm,
                        FISHER
                    );
                }
            }

            history = staking.getAddressHistoryByIndex(
                COMMON_USER_NO_STAKER_1.Address,
                (i + 1) - incorrectTxCount
            );

            if (input[i].usingStaker) {
                assertEq(
                    evvm.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher +
                        calculateRewardPerExecution(1) +
                        input[i].priorityFeeAmountEVVM,
                    "Error: balance of staker is not correct after public staking tx"
                );
            } else {
                assertEq(
                    evvm.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher,
                    "Error: balance of non-staker is not correct after public staking tx"
                );
            }

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    PRINCIPAL_TOKEN_ADDRESS
                ),
                amountBeforeUser +
                    (
                        input[i].isStaking
                            ? 0
                            : (
                                staking.getUserAmountStaked(
                                    COMMON_USER_NO_STAKER_1.Address
                                ) == 0
                                    ? staking.priceOfStaking() *
                                        stakingFullAmountBefore
                                    : staking.priceOfStaking() *
                                        input[i].stakingAmount
                            )
                    ),
                "Error: balance of user is not correct after public staking tx"
            );

            assertEq(
                history.timestamp,
                block.timestamp,
                "Error: timestamp in history is not correct"
            );
            assertEq(
                history.transactionType,
                (
                    input[i].isStaking
                        ? DEPOSIT_HISTORY_SMATE_IDENTIFIER
                        : WITHDRAW_HISTORY_SMATE_IDENTIFIER
                ),
                "Error: transactionType in history is not correct"
            );

            if (input[i].isStaking) {
                assertEq(
                    history.amount,
                    input[i].stakingAmount,
                    "Error: amount in history is not correct"
                );

                assertEq(
                    history.totalStaked,
                    totalStakedBefore + input[i].stakingAmount,
                    "Error: totalStaked in history is not correct"
                );
            } else {
                assertEq(
                    history.amount,
                    (
                        staking.getUserAmountStaked(
                            COMMON_USER_NO_STAKER_1.Address
                        ) == 0
                            ? stakingFullAmountBefore
                            : input[i].stakingAmount
                    ),
                    "Error: amount in history is not correct"
                );

                assertEq(
                    history.totalStaked,
                    totalStakedBefore -
                        (
                            staking.getUserAmountStaked(
                                COMMON_USER_NO_STAKER_1.Address
                            ) == 0
                                ? stakingFullAmountBefore
                                : input[i].stakingAmount
                        ),
                    "Error: totalStaked in history is not correct"
                );
            }
        }
    }
}

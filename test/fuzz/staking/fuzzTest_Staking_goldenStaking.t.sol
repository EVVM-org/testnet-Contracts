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

contract fuzzTest_Staking_goldenStaking is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        core.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _addBalance(10);

        bytes memory signaturePay = _executeSig_staking_goldenStaking(
            true,
            10
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(true, 10, signaturePay);

        vm.stopPrank();
    }

    function _addBalance(
        uint256 stakingAmount
    ) private returns (uint256 totalOfMate) {
        core.addBalance(
            GOLDEN_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount)
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (core.getRewardAmount() * 2) * numberOfTx;
    }

    struct GoldenStakingFuzzTestInput {
        bool isStaking;
        uint8 amount;
    }

    function test__fuzz__goldenStaking__staking(
        GoldenStakingFuzzTestInput[10] memory input
    ) external {
        uint256 totalAmount;
        uint256 amountBefore;
        uint256 stakingFullAmountBefore;
        uint256 totalStakedBefore;

        for (uint256 i = 0; i < input.length; i++) {
            console2.log("isStaking", input[i].isStaking);
            console2.log("amount", input[i].amount);

            totalStakedBefore = staking.getUserAmountStaked(
                GOLDEN_STAKER.Address
            );

            amountBefore = core.getBalance(
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

                totalAmount = _addBalance(input[i].amount);

                _executeFn_staking_goldenStaking(input[i].isStaking, input[i].amount);

                assertTrue(
                    core.isAddressStaker(GOLDEN_STAKER.Address),
                    "Error: golden user is not pointer as staker after staking"
                );
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

                    _executeFn_staking_goldenStaking(
                        input[i].isStaking,
                        stakingFullAmountBefore
                    );

                    assertFalse(
                        core.isAddressStaker(GOLDEN_STAKER.Address),
                        "Error: golden user is pointer as staker after full unstaking"
                    );
                } else {
                    _executeFn_staking_goldenStaking(
                        input[i].isStaking,
                        input[i].amount
                    );
                }
            }

            StakingStructs.HistoryMetadata memory history = staking
                .getAddressHistoryByIndex(GOLDEN_STAKER.Address, i + 1);

            assertEq(
                core.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
                amountBefore +
                    calculateRewardPerExecution(
                        core.isAddressStaker(GOLDEN_STAKER.Address) ? 1 : 0
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
                    ),
                "Error: balance after staking/unstaking is not correct"
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
                ),
                "Error: amount in history is not correct"
            );
            if (input[i].isStaking) {
                assertEq(
                    history.totalStaked,
                    totalStakedBefore + input[i].amount,
                    "Error: totalStaked is not correct after staking"
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
                        ),
                    "Error: totalStaked is not correct after unstaking"
                );
            }
        }
    }
}

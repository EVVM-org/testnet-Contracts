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

contract fuzzTest_Staking_presaleStaking is Test, Constants {
    function executeBeforeSetUp() internal override {
        /**
         *  @dev Because presale staking is disabled by default in 
                 testnet contracts, we need to enable it here
         */
        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        staking.prepareChangeAllowPresaleStaking();

        skip(1 days);
        staking.confirmChangeAllowPublicStaking();
        staking.confirmChangeAllowPresaleStaking();

        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        _addBalance(COMMON_USER_NO_STAKER_1.Address, true, 0);

        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            0,
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            COMMON_USER_NO_STAKER_1
        );
    }

    function _addBalance(
        address user,
        bool isStaking,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        core.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (isStaking ? staking.priceOfStaking() : 0) + priorityFee
        );
        return (staking.priceOfStaking(), priorityFee);
    }

    function calculateRewardPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (core.getRewardAmount() * 2) * numberOfTx;
    }

    struct PresaleStakingFuzzTestInput {
        bool isStaking;
        bool usingStaker;
        uint144 nonceStaking;
        uint144 noncePay;
        uint16 priorityFeeAmountEVVM;
    }

    function test__fuzz__presaleStaking(
        PresaleStakingFuzzTestInput[20] memory input
    ) external {
        StakingStructs.HistoryMetadata memory history;
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
                core.getIfUsedAsyncNonce(
                    COMMON_USER_NO_STAKER_1.Address,
                    input[i].noncePay
                )
            ) {
                incorrectTxCount++;
                continue;
            }

            if (input[i].nonceStaking == input[i].noncePay) {
                incorrectTxCount++;
                continue;
            }

            FISHER = input[i].usingStaker
                ? COMMON_USER_STAKER
                : COMMON_USER_NO_STAKER_2;

            amountBeforeFisher = core.getBalance(
                FISHER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            );

            amountBeforeUser = core.getBalance(
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

                _addBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    true,
                    uint256(input[i].priorityFeeAmountEVVM)
                );

                _executeFn_staking_presaleStaking(
                    COMMON_USER_NO_STAKER_1,
                    true,
                    address(0),
                    input[i].nonceStaking,
                    uint256(input[i].priorityFeeAmountEVVM),
                    input[i].noncePay,
                    FISHER
                );
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

                _addBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    false,
                    uint256(input[i].priorityFeeAmountEVVM)
                );

                _executeFn_staking_presaleStaking(
                    COMMON_USER_NO_STAKER_1,
                    false,
                    address(0),
                    input[i].nonceStaking,
                    uint256(input[i].priorityFeeAmountEVVM),
                    input[i].noncePay,
                    FISHER
                );
            }

            history = staking.getAddressHistoryByIndex(
                COMMON_USER_NO_STAKER_1.Address,
                (i + 1) - incorrectTxCount
            );

            assertEq(
                core.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    PRINCIPAL_TOKEN_ADDRESS
                ),
                amountBeforeUser +
                    (input[i].isStaking ? 0 : staking.priceOfStaking() * 1),
                "Error: balance of user is not correct after presale staking tx"
            );

            if (FISHER.Address == COMMON_USER_STAKER.Address) {
                assertEq(
                    core.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher +
                        calculateRewardPerExecution(1) +
                        uint256(input[i].priorityFeeAmountEVVM),
                    "Error: balance of staker is not correct after presale staking tx"
                );
            } else {
                assertEq(
                    core.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                    amountBeforeFisher,
                    "Error: balance of non-staker is not correct after presale staking tx"
                );
            }

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

            assertEq(history.amount, 1);

            if (input[i].isStaking) {
                assertEq(
                    history.totalStaked,
                    totalStakedBefore + 1,
                    "Error: totalStaked in history is not correct"
                );
            } else {
                assertEq(
                    history.totalStaked,
                    totalStakedBefore - 1,
                    "Error: totalStaked in history is not correct"
                );
            }
        }
    }
}

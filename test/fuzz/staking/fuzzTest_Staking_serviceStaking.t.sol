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

contract fuzzTest_Staking_serviceStaking is Test, Constants {
    MockContractToStake mockContract;

    function executeBeforeSetUp() internal override {
        mockContract = new MockContractToStake(address(staking));

        _addBalance(address(mockContract), 10);

        mockContract.stake(10);
    }

    function _addBalance(
        address user,
        uint256 stakingAmount
    ) private returns (uint256 totalOfMate) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount)
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
    }

    function getAmountOfRewardsPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    struct FuzzTestInput {
        bool isStaking;
        uint8 amount;
    }

    function test__fuzz__publicServiceStaking(
        FuzzTestInput[20] memory input
    ) external {
        uint256 counterTx = 0;
        uint256 amountStakingBefore;

        for (uint256 i = 0; i < input.length; i++) {
            amountStakingBefore = staking.getUserAmountStaked(
                address(mockContract)
            );

            if (input[i].isStaking) {
                if (
                    evvm.getBalance(
                        address(mockContract),
                        PRINCIPAL_TOKEN_ADDRESS
                    ) < staking.priceOfStaking() * input[i].amount
                ) {
                    uint256 totalOfStakeNeeded = input[i].amount -
                        (evvm.getBalance(
                            address(mockContract),
                            PRINCIPAL_TOKEN_ADDRESS
                        ) / staking.priceOfStaking());
                    _addBalance(address(mockContract), totalOfStakeNeeded);
                }

                if (staking.getUserAmountStaked(address(mockContract)) == 0)
                    skip(staking.getSecondsToUnlockStaking());

                mockContract.stake(input[i].amount);
            } else {
                if (
                    input[i].amount >
                    staking.getUserAmountStaked(address(mockContract))
                ) {
                    input[i].amount = uint8(
                        staking.getUserAmountStaked(address(mockContract))
                    );
                }

                if (input[i].amount == 0) continue;

                if (
                    staking.getUserAmountStaked(address(mockContract)) ==
                    input[i].amount
                ) skip(staking.getSecondsToUnlockFullUnstaking());

                mockContract.unstake(input[i].amount);
            }

            counterTx++;

            StakingStructs.HistoryMetadata memory history = staking
                .getAddressHistoryByIndex(address(mockContract), counterTx);

            assertEq(
                history.timestamp,
                block.timestamp,
                "Error: timestamp in history is not correct"
            );
            assertEq(
                history.transactionType,
                input[i].isStaking
                    ? DEPOSIT_HISTORY_SMATE_IDENTIFIER
                    : WITHDRAW_HISTORY_SMATE_IDENTIFIER,
                "Error: transactionType in history is not correct"
            );
            assertEq(
                history.amount,
                input[i].amount,
                "Error: amount in history is not correct"
            );
            if (input[i].isStaking)
                assertEq(
                    history.totalStaked,
                    amountStakingBefore + input[i].amount,
                    "Error: totalStaked in history is not correct"
                );
            else
                assertEq(
                    history.totalStaked,
                    amountStakingBefore - input[i].amount,
                    "Error: totalStaked in history is not correct"
                );
        }
    }
}

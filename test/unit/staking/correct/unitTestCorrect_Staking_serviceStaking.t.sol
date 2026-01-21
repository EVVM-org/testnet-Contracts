// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants, MockContractToStake} from "test/Constants.sol";
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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_Staking_serviceStaking is Test, Constants {
    MockContractToStake mockContract;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();

        vm.stopPrank();

        mockContract = new MockContractToStake(address(staking));
    }

    function giveMateToExecute(
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

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * nPF: No priority fee
     * PF: Includes priority fee
     */

    function test__unit_correct__publicServiceStaking__stake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 totalOfMate = giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        assertEq(evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS), 0);

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + totalOfMate
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicServiceStaking__unstake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        mockContract.unstake(5);

        assert(evvm.isAddressStaker(address(mockContract)));

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 5
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore +
                (staking.priceOfStaking() * 5) +
                evvm.getRewardAmount()
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 5);
        assertEq(history[1].totalStaked, 5);
    }

    function test__unit_correct__publicServiceStaking__fullUnstake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        skip(staking.getSecondsToUnlockFullUnstaking());

        mockContract.unstake(10);

        assert(!evvm.isAddressStaker(address(mockContract)));

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + evvm.getRewardAmount()
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[0].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 10);
        assertEq(history[1].totalStaked, 0);
    }

    function test__unit_correct__publicServiceStaking__stakeAfterFullUnstake()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        skip(staking.getSecondsToUnlockFullUnstaking());

        mockContract.unstake(10);

        skip(staking.getSecondsToUnlockStaking());

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        assertEq(evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS), 0);

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore +
                (staking.priceOfStaking() * 10) +
                evvm.getRewardAmount()
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[0].timestamp,
            block.timestamp -
                staking.getSecondsToUnlockFullUnstaking() -
                staking.getSecondsToUnlockStaking()
        );
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(
            history[1].timestamp,
            block.timestamp - staking.getSecondsToUnlockStaking()
        );
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 10);
        assertEq(history[1].totalStaked, 0);

        assertEq(history[2].timestamp, block.timestamp);
        assert(history[2].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 10);
        assertEq(history[2].totalStaked, 10);
    }
}

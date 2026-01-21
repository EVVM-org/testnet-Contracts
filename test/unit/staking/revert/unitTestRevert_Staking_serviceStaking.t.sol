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
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/staking/lib/ErrorsLib.sol";

contract unitTestRevert_Staking_serviceStaking is Test, Constants {
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

    function test__unit_revert__publicServiceStaking__prepareServiceStaking__AddressIsNotAService()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        giveMateToExecute(WILDCARD_USER.Address, 10);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotAService.selector);
        staking.prepareServiceStaking(10);
        vm.stopPrank();

        assert(!evvm.isAddressStaker(address(WILDCARD_USER.Address)));

        assertEq(
            evvm.getBalance(address(WILDCARD_USER.Address), PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore
        );

        assertEq(staking.getSizeOfAddressHistory(WILDCARD_USER.Address), 0);
    }

    function test__unit_revert__publicServiceStaking__confirmServiceStaking__AddressIsNotAService()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 amountStaking = giveMateToExecute(WILDCARD_USER.Address, 10);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotAService.selector);
        staking.confirmServiceStaking();
        vm.stopPrank();

        assert(!evvm.isAddressStaker(address(WILDCARD_USER.Address)));

        assertEq(
            evvm.getBalance(address(WILDCARD_USER.Address), PRINCIPAL_TOKEN_ADDRESS),
            amountStaking
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore
        );

        assertEq(staking.getSizeOfAddressHistory(WILDCARD_USER.Address), 0);
    }

    function test__unit_revert__publicServiceStaking__confirmServiceStaking__ServiceDoesNotFulfillCorrectStakingAmount()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 amountStaking = giveMateToExecute(address(mockContract), 10);

        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorsLib.ServiceDoesNotFulfillCorrectStakingAmount.selector,
                (5 * staking.priceOfStaking())
            )
        );
        mockContract.stakeWithAmountDiscrepancy(10, 5);

        assert(!evvm.isAddressStaker(address(mockContract)));

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            amountStaking
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore
        );

        assertEq(staking.getSizeOfAddressHistory(address(mockContract)), 0);
    }

    function test__unit_revert__publicServiceStaking__confirmServiceStaking__ServiceDoesNotStakeInSameTx()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 amountStaking = giveMateToExecute(address(mockContract), 10);

        mockContract.stakeJustInPartTwo(10);

        skip(1);

        vm.expectRevert(ErrorsLib.ServiceDoesNotStakeInSameTx.selector);
        mockContract.stakeJustConfirm();

        assert(!evvm.isAddressStaker(address(mockContract)));

        assertEq(evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS), 0);

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + amountStaking
        );

        assertEq(staking.getSizeOfAddressHistory(address(mockContract)), 0);
    }

    function test__unit_revert__publicServiceStaking__confirmServiceStaking__AddressMismatch()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        MockContractToStake auxMockContract = new MockContractToStake(
            address(staking)
        );

        uint256 amountStaking = giveMateToExecute(address(mockContract), 10);

        giveMateToExecute(address(auxMockContract), 10);

        mockContract.stakeJustInPartTwo(10);

        vm.expectRevert(ErrorsLib.AddressMismatch.selector);
        auxMockContract.stakeJustConfirm();

        assert(!evvm.isAddressStaker(address(mockContract)));

        assertEq(evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS), 0);

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + amountStaking
        );

        assertEq(staking.getSizeOfAddressHistory(address(mockContract)), 0);
    }

    function test__unit_correct__publicServiceStaking__fullUnstake_AddressMustWaitToFullUnstake()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 amountStaking = giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        skip(staking.getSecondsToUnlockFullUnstaking() - 50);

        vm.expectRevert(ErrorsLib.AddressMustWaitToFullUnstake.selector);
        mockContract.unstake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        assertEq(evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS), 0);

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + amountStaking
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[0].timestamp,
            block.timestamp - (staking.getSecondsToUnlockFullUnstaking() - 50)
        );
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicServiceStaking__stakeAfterFullUnstake_AddressMustWaitToStakeAgain()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(120);
        skip(1 days);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();

        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        giveMateToExecute(address(mockContract), 10);

        mockContract.stake(10);

        assert(evvm.isAddressStaker(address(mockContract)));

        skip(staking.getSecondsToUnlockFullUnstaking());

        mockContract.unstake(10);

        skip(staking.getSecondsToUnlockStaking() - 10);

        vm.expectRevert(ErrorsLib.AddressMustWaitToStakeAgain.selector);
        mockContract.stake(10);

        assert(!evvm.isAddressStaker(address(mockContract)));

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            (staking.priceOfStaking() * 10)
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
            block.timestamp -
                (staking.getSecondsToUnlockFullUnstaking() +
                    (staking.getSecondsToUnlockStaking() - 10))
        );
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(
            history[1].timestamp,
            block.timestamp - (staking.getSecondsToUnlockStaking() - 10)
        );
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 10);
        assertEq(history[1].totalStaked, 0);
    }

    function test__unit_revert__publicServiceStaking__unstake__AddressIsNotAService()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(ErrorsLib.AddressIsNotAService.selector);
        staking.serviceUnstaking(10);
        vm.stopPrank();
    }
}

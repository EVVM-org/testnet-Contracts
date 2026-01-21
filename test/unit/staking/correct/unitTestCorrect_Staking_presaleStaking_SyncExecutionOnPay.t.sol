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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_Staking_presaleStaking_SyncExecutionOnPay is
    Test,
    Constants
{
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function giveMateToExecute(
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

    function makeSignature(
        bool isStaking,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityEVVM,
        uint256 nonceSmate
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
                COMMON_USER_NO_STAKER_1.PrivateKey,
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
                COMMON_USER_NO_STAKER_1.PrivateKey,
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
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                isStaking,
                1,
                nonceSmate
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
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

    function test__unit_correct__presaleStaking_AsyncExecution__stake_nS_nPF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                address(staking)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1000001000001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1000001000001,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__stake_nS_PF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0.000001 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                address(staking)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1000001000001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1000001000001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__unstake_nS_nPF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(history[0].timestamp, block.timestamp);
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(history[1].timestamp, block.timestamp);
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        console2.log("history ts", history[2].timestamp);

        assertEq(history[2].timestamp, block.timestamp);
        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__fullUnstake_nS_nPF()
        external
    {
        giveMateToExecute(COMMON_USER_NO_STAKER_1.Address, 2, 0);

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            103
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(
            history[0].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(
            history[1].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        console2.log("history ts", history[2].timestamp);

        assertEq(
            history[2].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);

        assertEq(history[3].timestamp, block.timestamp);
        assertEq(history[3].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[3].amount, 1);
        assertEq(history[3].totalStaked, 0);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__fullUnstake_nS_PF()
        external
    {
        giveMateToExecute(COMMON_USER_NO_STAKER_1.Address, 2, 0.004 ether);

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 1");

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 2");

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 3");

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            103
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 4");

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(
            history[0].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(
            history[1].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        console2.log("history ts", history[2].timestamp);

        assertEq(
            history[2].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);

        assertEq(history[3].timestamp, block.timestamp);
        assertEq(history[3].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[3].amount, 1);
        assertEq(history[3].totalStaked, 0);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__stake_S_nPF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                address(staking)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1000001000001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1000001000001,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(1) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__stake_S_PF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0.000001 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                address(staking)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1000001000001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1000001000001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(1) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__unstake_S_nPF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(3) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(history[1].timestamp, block.timestamp);
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        console2.log("history ts", history[2].timestamp);

        assertEq(history[2].timestamp, block.timestamp);
        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__fullUnstake_S_nPF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            103
        );

        //!!! como en este no hay un pf solo se ejecuta un unico stake

        console.log(evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS));

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(4) + totalOfPriorityFee
        );

        assertEq(
            history[0].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(
            history[1].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        console2.log("history ts", history[2].timestamp);

        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);

        assertEq(history[3].timestamp, block.timestamp);
        assertEq(history[3].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[3].amount, 1);
        assertEq(history[3].totalStaked, 0);
    }

    function test__unit_correct__presaleStaking_AsyncExecution__fullUnstake_S_PF()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0.004 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            100
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 1");

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            101
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 2");

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            102
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 3");

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            103
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        console2.log("pass 4");

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );
        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(4) + totalOfPriorityFee
        );

        assertEq(
            history[0].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[0].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 1);
        assertEq(history[0].totalStaked, 1);

        assertEq(
            history[1].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[1].transactionType, DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 1);
        assertEq(history[1].totalStaked, 2);

        assertEq(
            history[2].timestamp,
            block.timestamp - staking.getSecondsToUnlockFullUnstaking()
        );
        assertEq(history[2].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[2].amount, 1);
        assertEq(history[2].totalStaked, 1);

        assertEq(history[3].timestamp, block.timestamp);
        assertEq(history[3].transactionType, WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[3].amount, 1);
        assertEq(history[3].totalStaked, 0);
    }
}

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
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_Staking_publicStaking_SyncExecutionOnPay is
    Test,
    Constants
{

    
    
    
    

    function executeBeforeSetUp() internal override {
        

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();

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
        uint256 amountOfSmate,
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
                    staking.priceOfStaking() * amountOfSmate,
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
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                isStaking,
                amountOfSmate,
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

    function test__unit_correct__publicStaking__stake_nS_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicStaking__unstake_nS_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            5,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            5,
            1002,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 5);
        assertEq(history[1].totalStaked, 5);
    }

    function test__unit_correct__publicStaking__fullUnstake_nS_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

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

    function test__unit_correct__publicStaking__stakeAfterFullUnstake_nS_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockStaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1003
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1003,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            history[0].timestamp,
            block.timestamp -
                (staking.getSecondsToUnlockFullUnstaking() +
                    staking.getSecondsToUnlockStaking())
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

    function test__unit_correct__publicStaking__stake_nS_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.001 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicStaking__unstake_nS_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.002 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            5,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            5,
            1002,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 5);
        assertEq(history[1].totalStaked, 5);
    }

    function test__unit_correct__publicStaking__fullUnstake_nS_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.002 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

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

    function test__unit_correct__publicStaking__stakeAfterFullUnstake_nS_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.003 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockStaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1003
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1003,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(COMMON_USER_NO_STAKER_1.Address)
            );

        history = staking.getAddressHistory(COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            history[0].timestamp,
            block.timestamp -
                (staking.getSecondsToUnlockFullUnstaking() +
                    staking.getSecondsToUnlockStaking())
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

    function test__unit_correct__publicStaking__stake_S_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
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
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicStaking__unstake_S_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            5,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            5,
            1002,
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
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 5);
        assertEq(history[1].totalStaked, 5);
    }

    function test__unit_correct__publicStaking__fullUnstake_S_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
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

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

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

    function test__unit_correct__publicStaking__stakeAfterFullUnstake_S_nPF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockStaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1003
        );

        console.log("Executing stake after full unstake...");
        console.log("Amount of stakig:", evvm.getBalance(address(staking), address(1)));
        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1003,
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
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(
            history[0].timestamp,
            block.timestamp -
                (staking.getSecondsToUnlockFullUnstaking() +
                    staking.getSecondsToUnlockStaking())
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

    function test__unit_correct__publicStaking__stake_S_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.001 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            totalOfPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
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
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);
    }

    function test__unit_correct__publicStaking__unstake_S_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.002 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            5,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            5,
            1002,
            signatureStaking,
            0.001 ether,
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
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(history[0].timestamp, block.timestamp);
        assert(history[0].transactionType == DEPOSIT_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[0].amount, 10);
        assertEq(history[0].totalStaked, 10);

        assertEq(history[1].timestamp, block.timestamp);
        assert(history[1].transactionType == WITHDRAW_HISTORY_SMATE_IDENTIFIER);
        assertEq(history[1].amount, 5);
        assertEq(history[1].totalStaked, 5);
    }

    function test__unit_correct__publicStaking__fullUnstake_S_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.002 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            0.001 ether,
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
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

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

    function test__unit_correct__publicStaking__stakeAfterFullUnstake_S_PF() external {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            10,
            0.003 ether
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1001
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1001,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1002
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            10,
            1002,
            signatureStaking,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockStaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            10,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            1003
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            10,
            1003,
            signatureStaking,
            0.001 ether,
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
            getAmountOfRewardsPerExecution(history.length) + totalOfPriorityFee
        );

        assertEq(
            history[0].timestamp,
            block.timestamp -
                (staking.getSecondsToUnlockFullUnstaking() +
                    staking.getSecondsToUnlockStaking())
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

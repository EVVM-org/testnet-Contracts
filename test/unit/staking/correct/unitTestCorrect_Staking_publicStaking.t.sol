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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract unitTestCorrect_Staking_publicStaking is Test, Constants {
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    function _addBalance(
        AccountData memory user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount) + priorityFee
        );
        return ((staking.priceOfStaking() * stakingAmount), priorityFee);
    }

    struct Params {
        AccountData user;
        bool isStaking;
        uint256 amountOfStaking;
        uint256 nonce;
        bytes signatureStaking;
        uint256 priorityFeeEVVM;
        uint256 nonceEVVM;
        bool priorityFlagEVVM;
        bytes signatureEVVM;
    }

    function test__unit_correct__publicStaking__fisherNoStaking_staking()
        external
    {
        Params memory paramsSyncNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        Params memory paramsSyncPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 300003,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address) + 1,
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsSyncNpf.user,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.priorityFeeEVVM
        );

        (
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncNpf.user,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsSyncNpf.user.Address,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM,
            paramsSyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncNpf.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(paramsSyncNpf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncNpf.user.Address),
            "Error [sync execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[0].timestamp,
            block.timestamp,
            "Error [sync execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[0].amount,
            10,
            "Error [sync execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncNpf[0].totalStaked,
            10,
            "Error [sync execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsSyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [sync execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsAsyncNpf.user,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.priorityFeeEVVM
        );

        (
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncNpf.user,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsAsyncNpf.user.Address,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM,
            paramsAsyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncNpf.user.Address)
            );

        historyAsyncNpf = staking.getAddressHistory(
            paramsAsyncNpf.user.Address
        );
        assertTrue(
            evvm.isAddressStaker(paramsAsyncNpf.user.Address),
            "Error [async execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncNpf[1].timestamp,
            block.timestamp,
            "Error [async execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncNpf[1].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncNpf[1].amount,
            10,
            "Error [async execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncNpf[1].totalStaked,
            20,
            "Error [async execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [async execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [async execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsSyncPf.user,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.priorityFeeEVVM
        );

        (
            paramsSyncPf.signatureStaking,
            paramsSyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncPf.user,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsSyncPf.user.Address,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.signatureStaking,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM,
            paramsSyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncPf.user.Address)
            );

        historySyncPf = staking.getAddressHistory(paramsSyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncPf.user.Address),
            "Error [sync execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncPf[2].timestamp,
            block.timestamp,
            "Error [sync execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncPf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncPf[2].amount,
            10,
            "Error [sync execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncPf[2].totalStaked,
            30,
            "Error [sync execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(paramsSyncPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution priorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsAsyncPf.user,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.priorityFeeEVVM
        );

        (
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncPf.user,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsAsyncPf.user.Address,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM,
            paramsAsyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncPf.user.Address)
            );

        historyAsyncPf = staking.getAddressHistory(paramsAsyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsAsyncPf.user.Address),
            "Error [async execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncPf[3].timestamp,
            block.timestamp,
            "Error [async execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncPf[3].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncPf[3].amount,
            10,
            "Error [async execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncPf[3].totalStaked,
            40,
            "Error [async execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [async execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncPf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [async execution priorityFee]: User principal token balance should be 0 after staking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_staking()
        external
    {
        Params memory paramsSyncNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        Params memory paramsSyncPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 300003,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address) + 1,
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsSyncNpf.user,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.priorityFeeEVVM
        );

        (
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncNpf.user,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsSyncNpf.user.Address,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM,
            paramsSyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncNpf.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(paramsSyncNpf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncNpf.user.Address),
            "Error [sync execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[0].timestamp,
            block.timestamp,
            "Error [sync execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[0].amount,
            10,
            "Error [sync execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncNpf[0].totalStaked,
            10,
            "Error [sync execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 1) + paramsSyncNpf.priorityFeeEVVM,
            "Error [sync execution noPriorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsSyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [sync execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsAsyncNpf.user,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.priorityFeeEVVM
        );

        (
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncNpf.user,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsAsyncNpf.user.Address,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM,
            paramsAsyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncNpf.user.Address)
            );

        historyAsyncNpf = staking.getAddressHistory(
            paramsAsyncNpf.user.Address
        );
        assertTrue(
            evvm.isAddressStaker(paramsAsyncNpf.user.Address),
            "Error [async execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncNpf[1].timestamp,
            block.timestamp,
            "Error [async execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncNpf[1].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncNpf[1].amount,
            10,
            "Error [async execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncNpf[1].totalStaked,
            20,
            "Error [async execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM,
            "Error [async execution noPriorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [async execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsSyncPf.user,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.priorityFeeEVVM
        );

        (
            paramsSyncPf.signatureStaking,
            paramsSyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncPf.user,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsSyncPf.user.Address,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.signatureStaking,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM,
            paramsSyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncPf.user.Address)
            );

        historySyncPf = staking.getAddressHistory(paramsSyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncPf.user.Address),
            "Error [sync execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncPf[2].timestamp,
            block.timestamp,
            "Error [sync execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncPf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncPf[2].amount,
            10,
            "Error [sync execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncPf[2].totalStaked,
            30,
            "Error [sync execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 3) * 2) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM +
                paramsSyncPf.priorityFeeEVVM,
            "Error [sync execution priorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            evvm.getBalance(paramsSyncPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution priorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsAsyncPf.user,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.priorityFeeEVVM
        );

        (
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncPf.user,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsAsyncPf.user.Address,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM,
            paramsAsyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncPf.user.Address)
            );

        historyAsyncPf = staking.getAddressHistory(paramsAsyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsAsyncPf.user.Address),
            "Error [async execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncPf[3].timestamp,
            block.timestamp,
            "Error [async execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncPf[3].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncPf[3].amount,
            10,
            "Error [async execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncPf[3].totalStaked,
            40,
            "Error [async execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 4) * 2) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM +
                paramsSyncPf.priorityFeeEVVM +
                paramsAsyncPf.priorityFeeEVVM,
            "Error [async execution priorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncPf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error [async execution priorityFee]: User principal token balance should be 0 after staking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_unstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            30,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory paramsSyncNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 0,
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        Params memory paramsSyncPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 300003,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsSyncNpf.user, 0, paramsSyncNpf.priorityFeeEVVM);

        (
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncNpf.user,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsSyncNpf.user.Address,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM,
            paramsSyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncNpf.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(paramsSyncNpf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncNpf.user.Address),
            "Error [sync execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error [sync execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            5,
            "Error [sync execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            25,
            "Error [sync execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsSyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 5,
            "Error [sync execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsAsyncNpf.user, 0, paramsAsyncNpf.priorityFeeEVVM);

        (
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncNpf.user,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsAsyncNpf.user.Address,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM,
            paramsAsyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncNpf.user.Address)
            );

        historyAsyncNpf = staking.getAddressHistory(
            paramsAsyncNpf.user.Address
        );
        assertTrue(
            evvm.isAddressStaker(paramsAsyncNpf.user.Address),
            "Error [async execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncNpf[2].timestamp,
            block.timestamp,
            "Error [async execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncNpf[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncNpf[2].amount,
            5,
            "Error [async execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncNpf[2].totalStaked,
            20,
            "Error [async execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [async execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 10,
            "Error [async execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsSyncPf.user, 0, paramsSyncPf.priorityFeeEVVM);

        (
            paramsSyncPf.signatureStaking,
            paramsSyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncPf.user,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsSyncPf.user.Address,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.signatureStaking,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM,
            paramsSyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncPf.user.Address)
            );

        historySyncPf = staking.getAddressHistory(paramsSyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncPf.user.Address),
            "Error [sync execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncPf[3].timestamp,
            block.timestamp,
            "Error [sync execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncPf[3].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncPf[3].amount,
            5,
            "Error [sync execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncPf[3].totalStaked,
            15,
            "Error [sync execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [sync execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(paramsSyncPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 15,
            "Error [sync execution priorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsAsyncPf.user, 0, paramsAsyncPf.priorityFeeEVVM);

        (
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncPf.user,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsAsyncPf.user.Address,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM,
            paramsAsyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncPf.user.Address)
            );

        historyAsyncPf = staking.getAddressHistory(paramsAsyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsAsyncPf.user.Address),
            "Error [async execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncPf[4].timestamp,
            block.timestamp,
            "Error [async execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncPf[4].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncPf[4].amount,
            5,
            "Error [async execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncPf[4].totalStaked,
            10,
            "Error [async execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [async execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncPf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 20,
            "Error [async execution priorityFee]: User principal token balance should be incremented after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_unstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            30,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory paramsSyncNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 0,
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        Params memory paramsSyncPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 300003,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        Params memory paramsAsyncPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsSyncNpf.user, 0, paramsSyncNpf.priorityFeeEVVM);

        (
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncNpf.user,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsSyncNpf.user.Address,
            paramsSyncNpf.isStaking,
            paramsSyncNpf.amountOfStaking,
            paramsSyncNpf.nonce,
            paramsSyncNpf.signatureStaking,
            paramsSyncNpf.priorityFeeEVVM,
            paramsSyncNpf.nonceEVVM,
            paramsSyncNpf.priorityFlagEVVM,
            paramsSyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncNpf.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(paramsSyncNpf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncNpf.user.Address),
            "Error [sync execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error [sync execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            5,
            "Error [sync execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            25,
            "Error [sync execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 1) + paramsSyncNpf.priorityFeeEVVM,
            "Error [sync execution noPriorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            evvm.getBalance(
                paramsSyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 5,
            "Error [sync execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsAsyncNpf.user, 0, paramsAsyncNpf.priorityFeeEVVM);

        (
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncNpf.user,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsAsyncNpf.user.Address,
            paramsAsyncNpf.isStaking,
            paramsAsyncNpf.amountOfStaking,
            paramsAsyncNpf.nonce,
            paramsAsyncNpf.signatureStaking,
            paramsAsyncNpf.priorityFeeEVVM,
            paramsAsyncNpf.nonceEVVM,
            paramsAsyncNpf.priorityFlagEVVM,
            paramsAsyncNpf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncNpf.user.Address)
            );

        historyAsyncNpf = staking.getAddressHistory(
            paramsAsyncNpf.user.Address
        );
        assertTrue(
            evvm.isAddressStaker(paramsAsyncNpf.user.Address),
            "Error [async execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncNpf[2].timestamp,
            block.timestamp,
            "Error [async execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncNpf[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncNpf[2].amount,
            5,
            "Error [async execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncNpf[2].totalStaked,
            20,
            "Error [async execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM,
            "Error [async execution noPriorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncNpf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 10,
            "Error [async execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsSyncPf.user, 0, paramsSyncPf.priorityFeeEVVM);

        (
            paramsSyncPf.signatureStaking,
            paramsSyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsSyncPf.user,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsSyncPf.user.Address,
            paramsSyncPf.isStaking,
            paramsSyncPf.amountOfStaking,
            paramsSyncPf.nonce,
            paramsSyncPf.signatureStaking,
            paramsSyncPf.priorityFeeEVVM,
            paramsSyncPf.nonceEVVM,
            paramsSyncPf.priorityFlagEVVM,
            paramsSyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSyncPf.user.Address)
            );

        historySyncPf = staking.getAddressHistory(paramsSyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsSyncPf.user.Address),
            "Error [sync execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historySyncPf[3].timestamp,
            block.timestamp,
            "Error [sync execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historySyncPf[3].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [sync execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historySyncPf[3].amount,
            5,
            "Error [sync execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historySyncPf[3].totalStaked,
            15,
            "Error [sync execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 3) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM +
                paramsSyncPf.priorityFeeEVVM,
            "Error [sync execution priorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            evvm.getBalance(paramsSyncPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 15,
            "Error [sync execution priorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsAsyncPf.user, 0, paramsAsyncPf.priorityFeeEVVM);

        (
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            paramsAsyncPf.user,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsAsyncPf.user.Address,
            paramsAsyncPf.isStaking,
            paramsAsyncPf.amountOfStaking,
            paramsAsyncPf.nonce,
            paramsAsyncPf.signatureStaking,
            paramsAsyncPf.priorityFeeEVVM,
            paramsAsyncPf.nonceEVVM,
            paramsAsyncPf.priorityFlagEVVM,
            paramsAsyncPf.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsyncPf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsyncPf.user.Address)
            );

        historyAsyncPf = staking.getAddressHistory(paramsAsyncPf.user.Address);
        assertTrue(
            evvm.isAddressStaker(paramsAsyncPf.user.Address),
            "Error [async execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyAsyncPf[4].timestamp,
            block.timestamp,
            "Error [async execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyAsyncPf[4].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [async execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyAsyncPf[4].amount,
            5,
            "Error [async execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyAsyncPf[4].totalStaked,
            10,
            "Error [async execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 4) +
                paramsSyncNpf.priorityFeeEVVM +
                paramsAsyncNpf.priorityFeeEVVM +
                paramsSyncPf.priorityFeeEVVM +
                paramsAsyncPf.priorityFeeEVVM,
            "Error [async execution priorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            evvm.getBalance(
                paramsAsyncPf.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            staking.priceOfStaking() * 20,
            "Error [async execution priorityFee]: User principal token balance should be incremented after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_sync_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_async_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_sync_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_async_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.0001 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_sync_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_async_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_sync_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_async_fullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );
        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.0001 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as non-staker after full unstaking"
        );

        assertEq(
            historySyncNpf[1].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[1].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[1].totalStaked,
            0,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_sync_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_async_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_sync_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_async_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }


    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_sync_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_async_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_sync_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_async_stakingAfterfullunstaking()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            true,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySyncNpf = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "Error: User should be marked as staker after staking"
        );

        assertEq(
            historySyncNpf[2].timestamp,
            block.timestamp,
            "Error: History timestamp mismatch"
        );
        assertEq(
            historySyncNpf[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: History transaction type mismatch"
        );
        assertEq(
            historySyncNpf[2].amount,
            10,
            "Error: History amount mismatch"
        );
        assertEq(
            historySyncNpf[2].totalStaked,
            10,
            "Error: History total staked mismatch"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );


        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }
}

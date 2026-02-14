// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**                                                                                                        
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄ 
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██   
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██   
                                                    
                                                    
                                                    
 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄          
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██            
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██                                                    
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/StakingStructs.sol";

contract unitTestCorrect_Staking_publicStaking is Test, Constants {
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    function _addBalance(
        AccountData memory user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        core.addBalance(
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
        bytes signatureEVVM;
    }

    function test__unit_correct__publicStaking__fisherNoStaking_staking()
        external
    {
        Params memory paramsNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        Params memory paramsPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsNpf.user,
            paramsNpf.amountOfStaking,
            paramsNpf.priorityFeeEVVM
        );

        (
            paramsNpf.signatureStaking,
            paramsNpf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsNpf.user,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsNpf.user.Address,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.signatureStaking,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM,
            paramsNpf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsNpf.user.Address)
            );

        historyNpf = staking.getAddressHistory(paramsNpf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsNpf.user.Address),
            "Error [execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyNpf[0].timestamp,
            block.timestamp,
            "Error [execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyNpf[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyNpf[0].amount,
            10,
            "Error [execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyNpf[0].totalStaked,
            10,
            "Error [execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            core.getBalance(paramsNpf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsPf.user,
            paramsPf.amountOfStaking,
            paramsPf.priorityFeeEVVM
        );

        (
            paramsPf.signatureStaking,
            paramsPf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsPf.user,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsPf.user.Address,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.signatureStaking,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM,
            paramsPf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyPf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsPf.user.Address)
            );

        historyPf = staking.getAddressHistory(paramsPf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsPf.user.Address),
            "Error [execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyPf[1].timestamp,
            block.timestamp,
            "Error [execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyPf[1].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyPf[1].amount,
            10,
            "Error [execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyPf[1].totalStaked,
            20,
            "Error [execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            core.getBalance(paramsPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution priorityFee]: User principal token balance should be 0 after staking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_staking()
        external
    {
        Params memory paramsNpf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        Params memory paramsPf = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsNpf.user,
            paramsNpf.amountOfStaking,
            paramsNpf.priorityFeeEVVM
        );

        (
            paramsNpf.signatureStaking,
            paramsNpf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsNpf.user,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsNpf.user.Address,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.signatureStaking,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM,
            paramsNpf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsNpf.user.Address)
            );

        historyNpf = staking.getAddressHistory(paramsNpf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsNpf.user.Address),
            "Error [execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyNpf[0].timestamp,
            block.timestamp,
            "Error [execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyNpf[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyNpf[0].amount,
            10,
            "Error [execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyNpf[0].totalStaked,
            10,
            "Error [execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((core.getRewardAmount() * 2) * 1) + paramsNpf.priorityFeeEVVM,
            "Error [execution noPriorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            core.getBalance(paramsNpf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution noPriorityFee]: User principal token balance should be 0 after staking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(
            paramsPf.user,
            paramsPf.amountOfStaking,
            paramsPf.priorityFeeEVVM
        );

        (
            paramsPf.signatureStaking,
            paramsPf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsPf.user,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsPf.user.Address,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.signatureStaking,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM,
            paramsPf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyPf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsPf.user.Address)
            );

        historyPf = staking.getAddressHistory(paramsPf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsPf.user.Address),
            "Error [execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyPf[1].timestamp,
            block.timestamp,
            "Error [execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyPf[1].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error [execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyPf[1].amount,
            10,
            "Error [execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyPf[1].totalStaked,
            20,
            "Error [execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((core.getRewardAmount() * 2) * 2) +
                paramsNpf.priorityFeeEVVM +
                paramsPf.priorityFeeEVVM,
            "Error [execution priorityFee]: Fisher principal token balance should be incremented after staking"
        );

        assertEq(
            core.getBalance(paramsPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution priorityFee]: User principal token balance should be 0 after staking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_unstaking()
        external
    {
        _addBalance(USER, 30, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            30,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        Params memory paramsNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        Params memory paramsPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsNpf.user, 0, paramsNpf.priorityFeeEVVM);

        (
            paramsNpf.signatureStaking,
            paramsNpf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsNpf.user,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsNpf.user.Address,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.signatureStaking,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM,
            paramsNpf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsNpf.user.Address)
            );

        historyNpf = staking.getAddressHistory(paramsNpf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsNpf.user.Address),
            "Error [execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyNpf[1].timestamp,
            block.timestamp,
            "Error [execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyNpf[1].amount,
            5,
            "Error [execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyNpf[1].totalStaked,
            25,
            "Error [execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution noPriorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            core.getBalance(paramsNpf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 5,
            "Error [execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsPf.user, 0, paramsPf.priorityFeeEVVM);

        (
            paramsPf.signatureStaking,
            paramsPf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsPf.user,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            paramsPf.user.Address,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.signatureStaking,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM,
            paramsPf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyPf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsPf.user.Address)
            );

        historyPf = staking.getAddressHistory(paramsPf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsPf.user.Address),
            "Error [execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyPf[2].timestamp,
            block.timestamp,
            "Error [execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyPf[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyPf[2].amount,
            5,
            "Error [execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyPf[2].totalStaked,
            20,
            "Error [execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error [execution priorityFee]: Fisher principal token balance should be 0 after staking"
        );

        assertEq(
            core.getBalance(paramsPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error [execution priorityFee]: User principal token balance should be incremented after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_unstaking()
        external
    {
        _addBalance(USER, 30, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            30,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        Params memory paramsNpf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 200002,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        Params memory paramsPf = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 5,
            nonce: 400004,
            signatureStaking: "",
            priorityFeeEVVM: 0.001 ether,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async noPriorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsNpf.user, 0, paramsNpf.priorityFeeEVVM);

        (
            paramsNpf.signatureStaking,
            paramsNpf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsNpf.user,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsNpf.user.Address,
            paramsNpf.isStaking,
            paramsNpf.amountOfStaking,
            address(0),
            paramsNpf.nonce,
            paramsNpf.signatureStaking,
            paramsNpf.priorityFeeEVVM,
            paramsNpf.nonceEVVM,
            paramsNpf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsNpf.user.Address)
            );

        historyNpf = staking.getAddressHistory(paramsNpf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsNpf.user.Address),
            "Error [execution noPriorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyNpf[1].timestamp,
            block.timestamp,
            "Error [execution noPriorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyNpf[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [execution noPriorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyNpf[1].amount,
            5,
            "Error [execution noPriorityFee]: History amount mismatch"
        );
        assertEq(
            historyNpf[1].totalStaked,
            25,
            "Error [execution noPriorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((core.getRewardAmount() * 2) * 1) + paramsNpf.priorityFeeEVVM,
            "Error [execution noPriorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            core.getBalance(paramsNpf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 5,
            "Error [execution noPriorityFee]: User principal token balance should be incremented after unstaking"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(paramsPf.user, 0, paramsPf.priorityFeeEVVM);

        (
            paramsPf.signatureStaking,
            paramsPf.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            paramsPf.user,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            paramsPf.user.Address,
            paramsPf.isStaking,
            paramsPf.amountOfStaking,
            address(0),
            paramsPf.nonce,
            paramsPf.signatureStaking,
            paramsPf.priorityFeeEVVM,
            paramsPf.nonceEVVM,
            paramsPf.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyPf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsPf.user.Address)
            );

        historyPf = staking.getAddressHistory(paramsPf.user.Address);
        assertTrue(
            core.isAddressStaker(paramsPf.user.Address),
            "Error [execution priorityFee]: User should be marked as staker after staking"
        );

        assertEq(
            historyPf[2].timestamp,
            block.timestamp,
            "Error [execution priorityFee]: History timestamp mismatch"
        );
        assertEq(
            historyPf[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error [execution priorityFee]: History transaction type mismatch"
        );
        assertEq(
            historyPf[2].amount,
            5,
            "Error [execution priorityFee]: History amount mismatch"
        );
        assertEq(
            historyPf[2].totalStaked,
            20,
            "Error [execution priorityFee]: History total staked mismatch"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((core.getRewardAmount() * 2) * 2) +
                paramsNpf.priorityFeeEVVM +
                paramsPf.priorityFeeEVVM,
            "Error [execution priorityFee]: Fisher principal token balance should be incremented after unstaking"
        );

        assertEq(
            core.getBalance(paramsPf.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error [execution priorityFee]: User principal token balance should be incremented after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_fullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_fullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Fisher principal token balance should be 0 after full unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_fullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_fullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockFullUnstaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertFalse(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be incremented after full unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: User principal token balance should be incremented after full unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_noPriorityFee_stakingAfterfullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_publicStaking(
            USER,
            false,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherNoStaking_priorityFee_stakingAfterfullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_publicStaking(
            USER,
            false,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: Staker principal token balance should be 0 after unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_noPriorityFee_stakingAfterfullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_publicStaking(
            USER,
            false,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }

    function test__unit_correct__publicStaking__fisherStaking_priorityFee_stakingAfterfullunstaking()
        external
    {
        _addBalance(USER, 10, 0);
        _executeFn_staking_publicStaking(
            USER,
            true,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_publicStaking(
            USER,
            false,
            10,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
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
            signatureEVVM: ""
        });

        _addBalance(params.user, 0, params.priorityFeeEVVM);

        skip(staking.getSecondsToUnlockStaking());

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _executeSig_staking_publicStaking(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            address(0),
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySyncNpf = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );

        historySyncNpf = staking.getAddressHistory(params.user.Address);
        assertTrue(
            core.isAddressStaker(params.user.Address),
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
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() * 2) + params.priorityFeeEVVM,
            "Error: Staker principal token balance should be increased after unstaking"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: User principal token balance should be 0 after unstaking"
        );
    }
}

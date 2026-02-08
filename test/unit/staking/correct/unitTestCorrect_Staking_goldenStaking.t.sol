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

contract unitTestCorrect_Staking_goldenStaking is Test, Constants {
    function _addBalance(
        uint256 stakingAmount
    ) private returns (uint256 totalOfMate) {
        evvm.addBalance(
            GOLDEN_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount)
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
    }

    function test__unit_correct__goldenStaking__staking() external {
        uint256 totalOfMate = _addBalance(10);

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            GOLDEN_STAKER,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            totalOfMate,
            0,
            address(staking),
            evvm.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
            false
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(true, 10, signatureEVVM);

        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = staking.getAddressHistory(GOLDEN_STAKER.Address);

        assertTrue(
            evvm.isAddressStaker(GOLDEN_STAKER.Address),
            "golden user is not pointer as staker"
        );

        assertEq(
            evvm.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2),
            "balance after staking is not correct"
        );

        assertEq(
            history[0].timestamp,
            block.timestamp,
            "timestamp in history [0] is not correct"
        );

        assertEq(
            history[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "transactionType in history [0] is not correct"
        );

        assertEq(history[0].amount, 10, "amount in history [0] is not correct");

        assertEq(
            history[0].totalStaked,
            10,
            "totalStaked in history [0] is not correct"
        );
    }

    function test__unit_correct__goldenStaking__unstaking() external {
        _addBalance(10);

        _execute_makeGoldenStaking(true, 10);

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(false, 4, bytes(hex""));

        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = staking.getAddressHistory(GOLDEN_STAKER.Address);

        assertTrue(
            evvm.isAddressStaker(GOLDEN_STAKER.Address),
            "golden user must still be pointer as staker"
        );

        assertEq(
            evvm.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) + (staking.priceOfStaking() * 4),
            "balance after staking is not correct"
        );

        assertEq(
            history[1].timestamp,
            block.timestamp,
            "timestamp in history [1] is not correct"
        );

        assertEq(
            history[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "transactionType in history [1] is not correct"
        );

        assertEq(history[1].amount, 4, "amount in history [1] is not correct");

        assertEq(
            history[1].totalStaked,
            6,
            "totalStaked in history [1] is not correct"
        );
    }

    function test__unit_correct__goldenStaking__fullunstaking() external {
        uint256 amountToStake = _addBalance(10);

        _execute_makeGoldenStaking(true, 10);

        skip(staking.getSecondsToUnlockFullUnstaking());

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(false, 10, bytes(hex""));

        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = staking.getAddressHistory(GOLDEN_STAKER.Address);

        assertFalse(
            evvm.isAddressStaker(GOLDEN_STAKER.Address),
            "golden user must be pointer as not staker anymore"
        );

        assertEq(
            evvm.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2)) + amountToStake,
            "balance after staking is not correct"
        );

        assertEq(
            history[1].timestamp,
            block.timestamp,
            "timestamp in history [1] is not correct"
        );

        assertEq(
            history[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "transactionType in history [1] is not correct"
        );

        assertEq(history[1].amount, 10, "amount in history [1] is not correct");

        assertEq(
            history[1].totalStaked,
            0,
            "totalStaked in history [1] is not correct"
        );
    }

    function test__unit_correct__goldenStaking__stakeAfterFullunstaking()
        external
    {
        _addBalance(10);

        _execute_makeGoldenStaking(true, 10);

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makeGoldenStaking(false, 10);

        skip(staking.getSecondsToUnlockStaking());

        vm.startPrank(GOLDEN_STAKER.Address);
        staking.goldenStaking(
            true,
            10,
            _execute_makeGoldenStakingSignature(true, 10)
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(GOLDEN_STAKER.Address)
            );
        history = staking.getAddressHistory(GOLDEN_STAKER.Address);

        assertTrue(
            evvm.isAddressStaker(GOLDEN_STAKER.Address),
            "golden user must be pointer as staker again"
        );

        assertEq(
            evvm.getBalance(GOLDEN_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) * 2,
            "balance after staking is not correct"
        );

        assertEq(
            history[2].timestamp,
            block.timestamp,
            "timestamp in history [2] is not correct"
        );

        assertEq(
            history[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "transactionType in history [2] is not correct"
        );

        assertEq(history[2].amount, 10, "amount in history [2] is not correct");

        assertEq(
            history[2].totalStaked,
            10,
            "totalStaked in history [2] is not correct"
        );
    }
}

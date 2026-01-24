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

    function test__unit_correct__publicServiceStaking__stake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 totalOfMate = _addBalance(address(mockContract), 10);

        mockContract.stake(10);

        assertTrue(
            evvm.isAddressStaker(address(mockContract)),
            "Error: address should be recognized as staker"
        );

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: staker principal token balance should be zero after staking"
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + totalOfMate,
            "Error: staking contract principal token balance should be increased after staking"
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[0].timestamp,
            block.timestamp,
            "Error: staking history timestamp mismatch"
        );
        assertEq(
            history[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: staking history transaction type mismatch"
        );
        assertEq(
            history[0].amount,
            10,
            "Error: staking history amount mismatch"
        );
        assertEq(
            history[0].totalStaked,
            10,
            "Error: staking history total staked mismatch"
        );
    }

    function test__unit_correct__publicServiceStaking__unstake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        _addBalance(address(mockContract), 10);

        mockContract.stake(10);

        mockContract.unstake(5);

        assertTrue(
            evvm.isAddressStaker(address(mockContract)),
            "Error: address should be recognized as staker"
        );
        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 5,
            "Error: staker principal token balance mismatch after unstaking"
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore +
                (staking.priceOfStaking() * 5) +
                evvm.getRewardAmount(),
            "Error: staking contract principal token balance mismatch after unstaking"
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[1].timestamp,
            block.timestamp,
            "Error: unstaking history timestamp mismatch"
        );
        assertEq(
            history[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: unstaking history transaction type mismatch"
        );
        assertEq(
            history[1].amount,
            5,
            "Error: unstaking history amount mismatch"
        );
        assertEq(
            history[1].totalStaked,
            5,
            "Error: unstaking history total staked mismatch"
        );
    }

    function test__unit_correct__publicServiceStaking__fullUnstake() external {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        _addBalance(address(mockContract), 10);

        mockContract.stake(10);

        skip(staking.getSecondsToUnlockFullUnstaking());

        mockContract.unstake(10);

        assertFalse(
            evvm.isAddressStaker(address(mockContract)),
            "Error: address should not be recognized as staker after full unstake"
        );

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            staking.priceOfStaking() * 10,
            "Error: staker principal token balance mismatch after full unstake"
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore + evvm.getRewardAmount(),
            "Error: staking contract principal token balance mismatch after full unstake"
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

        assertEq(
            history[1].timestamp,
            block.timestamp,
            "Error: full unstaking history timestamp mismatch"
        );
        assertEq(
            history[1].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "Error: full unstaking history transaction type mismatch"
        );
        assertEq(
            history[1].amount,
            10,
            "Error: full unstaking history amount mismatch"
        );
        assertEq(
            history[1].totalStaked,
            0,
            "Error: full unstaking history total staked mismatch"
        );
    }

    function test__unit_correct__publicServiceStaking__stakeAfterFullUnstake()
        external
    {
        uint256 amountStakingBefore = evvm.getBalance(
            address(staking),
            PRINCIPAL_TOKEN_ADDRESS
        );

        _addBalance(address(mockContract), 10);

        mockContract.stake(10);

        skip(staking.getSecondsToUnlockFullUnstaking());

        mockContract.unstake(10);

        skip(staking.getSecondsToUnlockStaking());

        mockContract.stake(10);

        assertTrue(
            evvm.isAddressStaker(address(mockContract)),
            "Error: address should be recognized as staker after staking again"
        );

        assertEq(
            evvm.getBalance(address(mockContract), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error: staker principal token balance should be zero after staking again"
        );

        assertEq(
            evvm.getBalance(address(staking), PRINCIPAL_TOKEN_ADDRESS),
            amountStakingBefore +
                (staking.priceOfStaking() * 10) +
                evvm.getRewardAmount(),
            "Error: staking contract principal token balance mismatch after staking again"
        );

        Staking.HistoryMetadata[]
            memory history = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(address(mockContract))
            );

        history = staking.getAddressHistory(address(mockContract));

        assertEq(
            history[2].timestamp,
            block.timestamp,
            "Error: staking again history timestamp mismatch"
        );
        assertEq(
            history[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "Error: staking again history transaction type mismatch"
        );
        assertEq(
            history[2].amount,
            10,
            "Error: staking again history amount mismatch"
        );
        assertEq(
            history[2].totalStaked,
            10,
            "Error: staking again history total staked mismatch"
        );
    }
}

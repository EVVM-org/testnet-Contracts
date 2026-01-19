// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM functions
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";


contract unitTestCorrect_NameService_adminFunctions is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function test__unit_correct__proposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, ADMIN.Address);
        assertEq(proposal, WILDCARD_USER.Address);
        assertEq(timeToAccept, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelProposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        nameService.cancelProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, ADMIN.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__acceptProposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        skip(1 days);

        vm.startPrank(WILDCARD_USER.Address);
        nameService.acceptProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, WILDCARD_USER.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__proposeWithdrawPrincipalTokens() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        vm.stopPrank();

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, removeAmount);
        assertEq(time, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelWithdrawPrincipalTokenss() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        nameService.cancelWithdrawPrincipalTokens();
        vm.stopPrank();

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, 0);
        assertEq(time, 0);
    }

    function test__unit_correct__claimWithdrawPrincipalTokens() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        skip(1 days);
        nameService.claimWithdrawPrincipalTokens();
        vm.stopPrank();

        assertEq(
            evvm.getBalance(address(nameService), PRINCIPAL_TOKEN_ADDRESS),
            (totalInEvvm - removeAmount) + evvm.getRewardAmount()
        );

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, 0);
        assertEq(time, 0);
    }

    function test__unit_correct__proposeChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, address(evvm));
        assertEq(proposal, WILDCARD_USER.Address);
        assertEq(timeToAccept, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        nameService.cancelChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, address(evvm));
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__acceptChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        skip(1 days);
        nameService.acceptChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, WILDCARD_USER.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }
}

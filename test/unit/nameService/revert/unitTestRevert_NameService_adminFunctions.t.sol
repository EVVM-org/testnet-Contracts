// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   ___/ __ \ /  ___\   __\
|    |  |   |  |  ||  |    |  | \  ___/ \___ \ |  |  
|______/|___|  |__||__|    |__|  \___  /____  >|__|  
             \/                      \/     \/       
                                  __                 
_______  _______  __ ____________/  |_               
\_  __ _/ __ \  \/ _/ __ \_  __ \   __\              
 |  | \\  ___/\   /\  ___/|  | \/|  |                
 |__|   \___  >\_/  \___  |__|   |__|                
            \/          \/                                                                                 
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    NameServiceError
} from "@evvm/testnet-contracts/library/errors/NameServiceError.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";
import {
    StateError
} from "@evvm/testnet-contracts/library/errors/StateError.sol";

contract unitTestRevert_NameService_adminFunctions is Test, Constants {
    function test__unit_revert__proposeAdmin__SenderIsNotAdmin() external {
        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(proposal, address(0), "Proposal should be zero address");
        assertEq(timeToAccept, 0, "Time to accept should be zero");
    }

    function test__unit_revert__proposeAdmin__InvalidAdminProposal_addressZero()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.InvalidAdminProposal.selector);
        /* 🢃 To address zero 🢃 */
        nameService.proposeAdmin(address(0));
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(proposal, address(0), "Proposal should be zero address");
        assertEq(timeToAccept, 0, "Time to accept should be zero");
    }

    function test__unit_revert__proposeAdmin__InvalidAdminProposal_currentAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.InvalidAdminProposal.selector);
        /* 🢃 To current admin 🢃 */
        nameService.proposeAdmin(ADMIN.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(proposal, address(0), "Proposal should be zero address");
        assertEq(timeToAccept, 0, "Time to accept should be zero");
    }

    function test__unit_revert__cancelProposeAdmin__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.cancelProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp + 1 days,
            "Time to accept should remain unchanged"
        );
    }

    function test__unit_revert__acceptProposeAdmin__SenderIsNotProposedAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        skip(1 days);

        /* 🢃 Non proposed admin sender 🢃 */
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.SenderIsNotProposedAdmin.selector);
        nameService.acceptProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp,
            "Time to accept should remain unchanged"
        );
    }

    function test__unit_revert__acceptProposeAdmin__LockTimeNotExpired()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        /* 🢃 Proposed admin tries to accept before time lock expires 🢃 */
        skip(1 days - 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.LockTimeNotExpired.selector);
        nameService.acceptProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(
            current,
            ADMIN.Address,
            "Current admin should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp + 2 hours,
            "Time to accept should remain unchanged"
        );
    }

    function test__unit_revert__proposeWithdrawPrincipalTokens__SenderIsNotAdmin()
        external
    {
        uint256 balanceBefore = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.proposeWithdrawPrincipalTokens(1);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(address(nameService), PRINCIPAL_TOKEN_ADDRESS),
            balanceBefore,
            "Contract principal token balance should remain unchanged"
        );

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            0,
            "Proposed amount to withdraw tokens should be zero"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            0,
            "Time to accept amount to withdraw tokens should be zero"
        );
    }

    function test__unit_revert__proposeWithdrawPrincipalTokens__InvalidWithdrawAmount_zero()
        external
    {
        uint256 balanceBefore = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.InvalidWithdrawAmount.selector);
        /* 🢃 Withdraw amount zero 🢃 */
        nameService.proposeWithdrawPrincipalTokens(0);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(address(nameService), PRINCIPAL_TOKEN_ADDRESS),
            balanceBefore,
            "Contract principal token balance should remain unchanged"
        );

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            0,
            "Proposed amount to withdraw tokens should be zero"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            0,
            "Time to accept amount to withdraw tokens should be zero"
        );
    }

    function test__unit_revert__proposeWithdrawPrincipalTokens__InvalidWithdrawAmount_full()
        external
    {
        uint256 balanceBefore = evvm.getBalance(
            address(nameService),
            PRINCIPAL_TOKEN_ADDRESS
        );
        /* 🢃 Withdraw full contract balance 🢃 */
        uint256 contractBalance = balanceBefore;
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.InvalidWithdrawAmount.selector);
        nameService.proposeWithdrawPrincipalTokens(contractBalance);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(address(nameService), PRINCIPAL_TOKEN_ADDRESS),
            balanceBefore,
            "Contract principal token balance should remain unchanged"
        );

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            0,
            "Proposed amount to withdraw tokens should be zero"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            0,
            "Time to accept amount to withdraw tokens should be zero"
        );
    }

    function test__unit_revert__cancelWithdrawPrincipalTokens__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(1);
        vm.stopPrank();

        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.cancelWithdrawPrincipalTokens();
        vm.stopPrank();

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            1,
            "Proposed amount to withdraw tokens should be unchanged"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            block.timestamp + 1 days,
            "Time to accept amount to withdraw tokens should be unchanged"
        );
    }

    function test__unit_revert__claimWithdrawPrincipalTokens__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(1);
        vm.stopPrank();

        skip(1 days);

        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.claimWithdrawPrincipalTokens();
        vm.stopPrank();

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            1,
            "Proposed amount to withdraw tokens should be unchanged"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            block.timestamp,
            "Time to accept amount to withdraw tokens should be unchanged"
        );
    }

    function test__unit_revert__claimWithdrawPrincipalTokens__LockTimeNotExpired()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(1);
        vm.stopPrank();

        /* 🢃 Admin tries to claim before time lock expires 🢃 */
        skip(1 days - 2 hours);

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.LockTimeNotExpired.selector);
        nameService.claimWithdrawPrincipalTokens();
        vm.stopPrank();

        (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        ) = nameService.getProposedWithdrawAmountFullDetails();

        assertEq(
            proposalAmountToWithdrawTokens,
            1,
            "Proposed amount to withdraw tokens should be unchanged"
        );
        assertEq(
            timeToAcceptAmountToWithdrawTokens,
            block.timestamp + 2 hours,
            "Time to accept amount to withdraw tokens should be unchanged"
        );
    }

    function test__unit_revert__proposeChangeEvvmAddress__SenderIsNotAdmin()
        external
    {
        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(
            current,
            address(evvm),
            "Current EVVM address should remain unchanged"
        );
        assertEq(proposal, address(0), "Proposal should be zero address");
        assertEq(timeToAccept, 0, "Time to accept should be zero");
    }

    function test__unit_revert__proposeChangeEvvmAddress__InvalidEvvmAddress()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.InvalidEvvmAddress.selector);
        /* 🢃 To address zero 🢃 */
        nameService.proposeChangeEvvmAddress(address(0));
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(
            current,
            address(evvm),
            "Current EVVM address should remain unchanged"
        );
        assertEq(proposal, address(0), "Proposal should be zero address");
        assertEq(timeToAccept, 0, "Time to accept should be zero");
    }


    function test__unit_revert__cancelChangeEvvmAddress__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.cancelChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(
            current,
            address(evvm),
            "Current EVVM address should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp + 1 days,
            "Time to accept should remain unchanged"
        );
    }


    function test__unit_revert__acceptChangeEvvmAddress__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        skip(1 days);

        /* 🢃 Non admin sender 🢃 */
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(NameServiceError.SenderIsNotAdmin.selector);
        nameService.acceptChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(
            current,
            address(evvm),
            "Current EVVM address should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp,
            "Time to accept should remain unchanged"
        );
    }

    function test__unit_revert__acceptChangeEvvmAddress__LockTimeNotExpired()
        external
    {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        /* 🢃 Admin tries to accept before time lock expires 🢃 */
        skip(1 days - 2 hours);

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(NameServiceError.LockTimeNotExpired.selector);
        nameService.acceptChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(
            current,
            address(evvm),
            "Current EVVM address should remain unchanged"
        );
        assertEq(
            proposal,
            WILDCARD_USER.Address,
            "Proposal should remain unchanged"
        );
        assertEq(
            timeToAccept,
            block.timestamp + 2 hours,
            "Time to accept should remain unchanged"
        );
    }
}

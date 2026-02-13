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
import "@evvm/testnet-contracts/library/errors/StateError.sol";
import "@evvm/testnet-contracts/library/utils/governance/Admin.sol";

contract unitTestRevert_State_adminFunctions is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    function test__unit_revert__proposeUserValidator__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.proposeUserValidator(address(125));
        vm.stopPrank();
    }

    function test__unit_revert__cancelUserValidatorProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.cancelUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptUserValidatorProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        vm.stopPrank();
        skip(1 days);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.acceptUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptUserValidatorProposal__ProposalForUserValidatorNotReady()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        skip(10 minutes);
        vm.expectRevert(StateError.ProposalForUserValidatorNotReady.selector);
        state.acceptUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__proposeEvvmAddress__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.proposeEvvmAddress(address(125));
        vm.stopPrank();
    }

    function test__unit_revert__cancelEvvmAddressProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.cancelEvvmAddressProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptEvvmAddressProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        vm.stopPrank();
        skip(1 days);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(Admin.SenderIsNotAdmin.selector);
        state.acceptEvvmAddressProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptEvvmAddressProposal__ProposalForEvvmAddressNotReady()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        skip(10 minutes);
        vm.expectRevert(StateError.ProposalForEvvmAddressNotReady.selector);
        state.acceptEvvmAddressProposal();
        vm.stopPrank();
    }
}

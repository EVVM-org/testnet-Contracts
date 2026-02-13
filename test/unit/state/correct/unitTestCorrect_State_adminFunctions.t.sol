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

contract unitTestCorrect_State_adminFunctions is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    function test__unit_correct__proposeUserValidator() external {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getUserValidatorAddressDetails();

        assertEq(
            proposal.current,
            address(0),
            "Current user validator should be address(0) after proposal"
        );
        assertEq(
            proposal.proposal,
            address(125),
            "Proposed user validator should be address(125) after proposal"
        );
        assertGt(
            proposal.timeToAccept,
            block.timestamp,
            "Time to accept should be set in after proposal"
        );
    }

    function test__unit_correct__cancelUserValidatorProposal() external {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        state.cancelUserValidatorProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getUserValidatorAddressDetails();

        assertEq(
            proposal.current,
            address(0),
            "Current user validator should be address(0) after cancellation"
        );
        assertEq(
            proposal.proposal,
            address(0),
            "Proposed user validator should be address(0) after cancellation"
        );
        assertEq(
            proposal.timeToAccept,
            0,
            "Time to accept should be set to 0 after cancellation"
        );
    }

    function test__unit_correct__acceptUserValidatorProposal() external {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(125));
        skip(1 days);
        state.acceptUserValidatorProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getUserValidatorAddressDetails();

        assertEq(
            proposal.current,
            address(125),
            "Current user validator should be address(125) after confirmation"
        );
        assertEq(
            proposal.proposal,
            address(0),
            "Proposed user validator should be address(0) after confirmation"
        );
        assertEq(
            proposal.timeToAccept,
            0,
            "Time to accept should be set to 0 after confirmation"
        );
    }

    function test__unit_correct__proposeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getEvvmAddressDetails();

        assertEq(
            proposal.current,
            address(0),
            "Current evvm address should be address(0) after proposal"
        );
        assertEq(
            proposal.proposal,
            address(125),
            "Proposed evvm address should be address(125) after proposal"
        );
        assertGt(
            proposal.timeToAccept,
            block.timestamp,
            "Time to accept should be set in after proposal"
        );
    }

    function test__unit_correct__cancelEvvmAddressProposal() external {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        state.cancelEvvmAddressProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getEvvmAddressDetails();

        assertEq(
            proposal.current,
            address(0),
            "Current evvm address should be address(0) after cancellation"
        );
        assertEq(
            proposal.proposal,
            address(0),
            "Proposed evvm address should be address(0) after cancellation"
        );
        assertEq(
            proposal.timeToAccept,
            0,
            "Time to accept should be set to 0 after cancellation"
        );
    }

    function test__unit_correct__acceptEvvmAddressProposal() external {
        vm.startPrank(ADMIN.Address);
        state.proposeEvvmAddress(address(125));
        skip(1 days);
        state.acceptEvvmAddressProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = state
            .getEvvmAddressDetails();

        assertEq(
            proposal.current,
            address(125),
            "Current evvm address should be address(125) after confirmation"
        );
        assertEq(
            proposal.proposal,
            address(0),
            "Proposed evvm address should be address(0) after confirmation"
        );
        assertEq(
            proposal.timeToAccept,
            0,
            "Time to accept should be set to 0 after confirmation"
        );
    }
}

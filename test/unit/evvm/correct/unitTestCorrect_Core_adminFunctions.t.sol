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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestCorrect_Core_adminFunctions is Test, Constants {
    function setUp() public override {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        core = new Core(
            ADMIN.Address,
            address(staking),
            CoreStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );
        
        estimator = new Estimator(
            ACTIVATOR.Address,
            address(core),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(
            address(core),
            ADMIN.Address
        );

        staking.initializeSystemContracts(
            address(estimator),
            address(core)
        );
        treasury = new Treasury(address(core));
        core.initializeSystemContracts(
            address(nameService),
            address(treasury)
        );

        //

        executeBeforeSetUp();
    }

    function test__unit_correct__proposeAdmin() external {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        assertEq(
            core.getCurrentAdmin(),
            ADMIN.Address,
            "Admin should be proposed not changed yet"
        );
    }

    function test__unit_correct__acceptAdmin() external {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1 hours);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        core.acceptAdmin();

        vm.stopPrank();

        assertEq(
            core.getCurrentAdmin(),
            COMMON_USER_NO_STAKER_1.Address,
            "Admin should be changed"
        );
    }

    function test__unit_correct__rejectProposalAdmin() external {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.warp(block.timestamp + 10 hours);

        core.rejectProposalAdmin();

        vm.stopPrank();

        assertEq(
            core.getCurrentAdmin(),
            ADMIN.Address,
            "Admin should be same because proposal was rejected"
        );
    }

    function test__unit_correct__setEvvmID() external {
        vm.startPrank(ADMIN.Address);

        core.setEvvmID(888);

        assertEq(core.getEvvmID(), 888);

        skip(20 hours);

        core.setEvvmID(777);

        vm.stopPrank();

        assertEq(core.getEvvmID(), 777, "EvvmID should be changed");
    }

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    function test__unit_correct__proposeUserValidator() external {
        vm.startPrank(ADMIN.Address);
        core.proposeUserValidator(address(125));
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = core
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
        core.proposeUserValidator(address(125));
        core.cancelUserValidatorProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = core
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
        core.proposeUserValidator(address(125));
        skip(1 days);
        core.acceptUserValidatorProposal();
        vm.stopPrank();

        ProposalStructs.AddressTypeProposal memory proposal = core
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
}

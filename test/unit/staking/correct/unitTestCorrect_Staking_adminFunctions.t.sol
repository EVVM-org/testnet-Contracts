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

contract unitTestCorrect_Staking_adminFunctions is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function test__unit_correct__admin_addPresaleStaker() external {
        vm.startPrank(ADMIN.Address);
        staking.addPresaleStaker(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unit_correct__admin_addPresaleStakers() external {
        address[] memory stakers = new address[](2);
        stakers[0] = makeAddr("alice");
        stakers[1] = makeAddr("bob");

        vm.startPrank(ADMIN.Address);
        staking.addPresaleStakers(stakers);
        vm.stopPrank();
    }

    function test__unit_correct__admin_proposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unit_correct__admin_rejectProposalAdmin() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 2 hours);
        staking.rejectProposalAdmin();
        vm.stopPrank();
    }

    function test__unit_correct__admin_acceptNewAdmin() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(WILDCARD_USER.Address);
        staking.acceptNewAdmin();
        vm.stopPrank();
    }

    function test__unit_correct__admin_proposeGoldenFisher() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unit_correct__admin_rejectProposalGoldenFisher() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 2 hours);
        staking.rejectProposalGoldenFisher();
        vm.stopPrank();
    }

    function test__unit_correct__admin_acceptNewGoldenFisher() external {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 1 days + 1);
        staking.acceptNewGoldenFisher();
        vm.stopPrank();
    }

    function test__unit_correct__admin_proposeSetSecondsToUnlockStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();
    }

    function test__unit_correct__admin_rejectProposalSetSecondsToUnlockStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.warp(block.timestamp + 2 hours);
        staking.rejectProposalSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_acceptSetSecondsToUnlockStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.warp(block.timestamp + 1 days + 1);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_prepareSetSecondsToUnllockFullUnstaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();
    }

    function test__unit_correct__admin_cancelSetSecondsToUnllockFullUnstaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.warp(block.timestamp + 2 hours);
        staking.cancelSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_confirmSetSecondsToUnllockFullUnstaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.warp(block.timestamp + 1 days + 1);
        staking.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_prepareChangeAllowPublicStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_cancelChangeAllowPublicStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.warp(block.timestamp + 2 hours);
        staking.cancelChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_confirmChangeAllowPublicStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.warp(block.timestamp + 1 days + 1);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_prepareChangeAllowPresaleStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_cancelChangeAllowPresaleStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.warp(block.timestamp + 2 hours);
        staking.cancelChangeAllowPresaleStaking();
        vm.stopPrank();
    }

    function test__unit_correct__admin_confirmChangeAllowPresaleStaking()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.warp(block.timestamp + 1 days + 1);
        staking.confirmChangeAllowPresaleStaking();
        vm.stopPrank();
    }
}

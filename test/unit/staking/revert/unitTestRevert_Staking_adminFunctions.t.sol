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
import "@evvm/testnet-contracts/library/errors/StakingError.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract unitTestRevert_Staking_adminFunctions is Test, Constants {
    function test__unitRevert__addPresaleStaker__SenderIsNotAdmin() external {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unitRevert__addPresaleStaker__limitExceeded() external {
        vm.startPrank(ADMIN.Address);
        /*Yep... I know this is a lot of stakers */
        for (uint256 i = 0; i < 801; i++) {
            address newStaker = makeAddr(
                string(
                    abi.encodePacked(
                        "presale_staker_",
                        AdvancedStrings.uintToString(i)
                    )
                )
            );
            staking.addPresaleStaker(newStaker);
        }
        vm.expectRevert(StakingError.LimitPresaleStakersExceeded.selector);
        staking.addPresaleStaker(makeAddr("one_more_staker"));
        vm.stopPrank();
    }

    function test__unitRevert__addPresaleStakers__SenderIsNotAdmin() external {
        address[] memory stakers = new address[](2);
        stakers[0] = makeAddr("alice");
        stakers[1] = makeAddr("bob");

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.addPresaleStakers(stakers);
        vm.stopPrank();
    }

    function test__unitRevert__addPresaleStakers__LimitPresaleStakersExceeded()
        external
    {
        vm.startPrank(ADMIN.Address);
        for (uint256 i = 0; i < 800; i++) {
            address newStaker = makeAddr(
                string(
                    abi.encodePacked(
                        "presale_staker_",
                        AdvancedStrings.uintToString(i)
                    )
                )
            );
            staking.addPresaleStaker(newStaker);
        }

        address[] memory stakers = new address[](2);
        stakers[0] = makeAddr("alice");
        stakers[1] = makeAddr("bob");

        vm.expectRevert(StakingError.LimitPresaleStakersExceeded.selector);
        staking.addPresaleStakers(stakers);
        vm.stopPrank();
    }

    function test__unitRevert__proposeAdmin__SenderIsNotAdmin() external {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalAdmin__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.rejectProposalAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewAdmin__SenderIsNotProposedAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(StakingError.SenderIsNotProposedAdmin.selector);
        staking.acceptNewAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewAdmin__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();
        vm.warp(block.timestamp + 10 hours);
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.TimeToAcceptProposalNotReached.selector);
        staking.acceptNewAdmin();
        vm.stopPrank();
    }

    function test__unitRevert__proposeGoldenFisher__SenderIsNotAdmin()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalGoldenFisher__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 2 hours);
        vm.stopPrank();
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.rejectProposalGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewGoldenFisher__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.acceptNewGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__acceptNewGoldenFisher__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeGoldenFisher(WILDCARD_USER.Address);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert();
        staking.acceptNewGoldenFisher();
        vm.stopPrank();
    }

    function test__unitRevert__proposeSetSecondsToUnlockStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();
    }

    function test__unitRevert__rejectProposalSetSecondsToUnlockStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.rejectProposalSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__acceptSetSecondsToUnlockStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__acceptSetSecondsToUnlockStaking__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(2 days);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert(StakingError.TimeToAcceptProposalNotReached.selector);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareSetSecondsToUnllockFullUnstaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();
    }

    function test__unitRevert__cancelSetSecondsToUnllockFullUnstaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.cancelSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetSecondsToUnllockFullUnstaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmSetSecondsToUnllockFullUnstaking__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareSetSecondsToUnllockFullUnstaking(2 days);
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert(StakingError.TimeToAcceptProposalNotReached.selector);
        staking.confirmSetSecondsToUnllockFullUnstaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareChangeAllowPublicStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.prepareChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unitRevert__cancelChangeAllowPublicStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.cancelChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmChangeAllowPublicStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmChangeAllowPublicStaking__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert(StakingError.TimeToAcceptProposalNotReached.selector);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();
    }

    function test__unitRevert__prepareChangeAllowPresaleStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.prepareChangeAllowPresaleStaking();
        vm.stopPrank();
    }

    function test__unitRevert__cancelChangeAllowPresaleStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.cancelChangeAllowPresaleStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmChangeAllowPresaleStaking__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(WILDCARD_USER.Address);
        vm.expectRevert(StakingError.SenderIsNotAdmin.selector);
        staking.confirmChangeAllowPresaleStaking();
        vm.stopPrank();
    }

    function test__unitRevert__confirmChangeAllowPresaleStaking__TimeToAcceptProposalNotReached()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        vm.warp(block.timestamp + 10 hours);
        vm.expectRevert(StakingError.TimeToAcceptProposalNotReached.selector);
        staking.confirmChangeAllowPresaleStaking();
        vm.stopPrank();
    }
}

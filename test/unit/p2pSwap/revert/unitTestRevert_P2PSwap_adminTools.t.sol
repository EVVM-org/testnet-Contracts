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

import {Constants} from "test/Constants.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    CoreStorage
} from "@evvm/testnet-contracts/contracts/core/lib/CoreStorage.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";

contract unitTestRevert_P2PSwap_adminTools is Test, Constants {
    

    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }


    function test__unit_revert__proposeOwner_notOwner() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeOwner_notProposedUser() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeOwner();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeOwner_proposeExpired() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeOwner();
        vm.stopPrank();
    }

    function test__unit_revert__acceptOwner_notProposedUser() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        p2pSwap.acceptOwner();
        vm.stopPrank();
    }

    function test__unit_revert__acceptOwner_proposeExpired() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        p2pSwap.acceptOwner();
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillFixedPercentage_notOwner() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillFixedPercentage_wrongValues()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 1_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert();
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillFixedPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeFillFixedPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillFixedPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeFillFixedPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__acceptFillFixedPercentage_notOwner() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptFillFixedPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillFixedPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.acceptFillFixedPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__proposeFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillPropotionalPercentage_wrongValues()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 1_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert();
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillPropotionalPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillPropotionalPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.acceptFillPropotionalPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__proposePercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposePercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposePercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposePercentageFee_proposeExpired()
        external
    {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);

        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposePercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptPercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptPercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptPercentageFee_proposeExpired() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);

        vm.warp(block.timestamp  + 2 days);

        vm.expectRevert();
        p2pSwap.acceptPercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__proposeMaxLimitFillFixedFee_notOwner()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeMaxLimitFillFixedFee_notOwner()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeMaxLimitFillFixedFee_proposeExpired()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.warp(block.timestamp  + 2 days);

        vm.expectRevert();
        p2pSwap.rejectProposeMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptMaxLimitFillFixedFee_notOwner() external {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptMaxLimitFillFixedFee_proposeExpired()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);

        vm.warp(block.timestamp  + 2 days);
        vm.expectRevert();
        p2pSwap.acceptMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal_notEnoughBalance() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.000001 ether);

        vm.expectRevert();
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeWithdrawal_proposeExpired()
        external
    {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);

        vm.warp(block.timestamp  + 2 days);

        vm.expectRevert();
        p2pSwap.rejectProposeWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptWithdrawal_proposeExpired() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);

        vm.warp(block.timestamp  + 2 days);

        vm.expectRevert();
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }
}

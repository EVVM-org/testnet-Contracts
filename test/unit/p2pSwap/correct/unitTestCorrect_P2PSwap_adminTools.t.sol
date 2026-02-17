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

contract unitTestCorrect_P2PSwap_adminTools is Test, Constants {



    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }

    function test__unit_correct__proposeOwner() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        assertEq(p2pSwap.getOwnerProposal(), COMMON_USER_NO_STAKER_1.Address);
        assertEq(p2pSwap.getOwnerTimeToAccept(), block.timestamp + 1 days);
    }

    function test__unit_correct__rejectProposeOwner() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.sleep(4 hours);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        p2pSwap.rejectProposeOwner();
        vm.stopPrank();

        assertEq(p2pSwap.getOwnerProposal(), address(0));
    }

    function test__unit_correct__acceptOwner() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.sleep(4 hours);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        p2pSwap.acceptOwner();
        vm.stopPrank();

        assertEq(p2pSwap.getOwner(), COMMON_USER_NO_STAKER_1.Address);
        assertEq(p2pSwap.getOwnerProposal(), address(0));
    }

    function test__unit_correct__proposeFillFixedPercentage() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        P2PSwap.Percentage memory prop = p2pSwap.getRewardPercentageProposal();

        assertNotEq(prop.seller, sellerPercentage);
        assertNotEq(prop.service, servicePercentage);
        assertNotEq(prop.mateStaker, stakerPercentage);

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        prop = p2pSwap.getRewardPercentageProposal();

        assertEq(prop.seller, sellerPercentage);
        assertEq(prop.service, servicePercentage);
        assertEq(prop.mateStaker, stakerPercentage);
    }

    function test__unit_correct__rejectProposeFillFixedPercentage() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.sleep(4 hours);
        p2pSwap.rejectProposeFillFixedPercentage();
        vm.stopPrank();

        P2PSwap.Percentage memory prop = p2pSwap.getRewardPercentageProposal();
        assertEq(prop.seller, 0);
        assertEq(prop.service, 0);
        assertEq(prop.mateStaker, 0);
    }

    function test__unit_correct__acceptFillFixedPercentage() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.sleep(4 hours);
        p2pSwap.acceptFillFixedPercentage();
        vm.stopPrank();

        P2PSwap.Percentage memory reward = p2pSwap.getRewardPercentage();
        assertEq(reward.seller, sellerPercentage);
        assertEq(reward.service, servicePercentage);
        assertEq(reward.mateStaker, stakerPercentage);
    }

    function test__unit_correct__proposeFillPropotionalPercentage() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        P2PSwap.Percentage memory prop = p2pSwap.getRewardPercentageProposal();

        assertNotEq(prop.seller, sellerPercentage);
        assertNotEq(prop.service, servicePercentage);
        assertNotEq(prop.mateStaker, stakerPercentage);

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        prop = p2pSwap.getRewardPercentageProposal();

        assertEq(prop.seller, sellerPercentage);
        assertEq(prop.service, servicePercentage);
        assertEq(prop.mateStaker, stakerPercentage);
    }

    function test__unit_correct__rejectProposeFillPropotionalPercentage()
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
        vm.sleep(4 hours);
        p2pSwap.rejectProposeFillPropotionalPercentage();
        vm.stopPrank();

        P2PSwap.Percentage memory prop = p2pSwap.getRewardPercentageProposal();
        assertEq(prop.seller, 0);
        assertEq(prop.service, 0);
        assertEq(prop.mateStaker, 0);
    }

    function test__unit_correct__acceptFillPropotionalPercentage() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.sleep(4 hours);
        p2pSwap.acceptFillPropotionalPercentage();
        vm.stopPrank();

        P2PSwap.Percentage memory reward = p2pSwap.getRewardPercentage();
        assertEq(reward.seller, sellerPercentage);
        assertEq(reward.service, servicePercentage);
        assertEq(reward.mateStaker, stakerPercentage);
    }

    function test__unit_correct__proposePercentageFee() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();

        assertEq(p2pSwap.getProposalPercentageFee(), fee);
    }

    function test__unit_correct__rejectProposePercentageFee() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.sleep(4 hours);
        p2pSwap.rejectProposePercentageFee();
        vm.stopPrank();

        assertEq(p2pSwap.getProposalPercentageFee(), 0);
    }

    function test__unit_correct__acceptPercentageFee() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.sleep(4 hours);
        p2pSwap.acceptPercentageFee();
        vm.stopPrank();

        assertEq(p2pSwap.getPercentageFee(), fee);
    }

    function test__unit_correct__proposeMaxLimitFillFixedFee() external {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();

        assertEq(p2pSwap.getMaxLimitFillFixedFeeProposal(), prop);
    }

    function test__unit_correct__rejectProposeMaxLimitFillFixedFee() external {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.sleep(4 hours);
        p2pSwap.rejectProposeMaxLimitFillFixedFee();
        vm.stopPrank();

        assertEq(p2pSwap.getMaxLimitFillFixedFeeProposal(), 0);
    }

    function test__unit_correct__acceptMaxLimitFillFixedFee() external {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.sleep(4 hours);
        p2pSwap.acceptMaxLimitFillFixedFee();
        vm.stopPrank();

        assertEq(p2pSwap.getMaxLimitFillFixedFee(), prop);
    }

    function test__unit_correct__proposeWithdrawal() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();

        (
            address tokenToWithdraw,
            uint256 amountToWithdraw,
            address recipientToWithdraw,
            uint256 _timeToWithdrawal
        ) = p2pSwap.getProposedWithdrawal();

        assertEq(tokenToWithdraw, token);
        assertEq(amountToWithdraw, amount);
        assertEq(recipientToWithdraw, to);
    }

    function test__unit_correct__rejectProposeWithdrawal() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.sleep(4 hours);
        p2pSwap.rejectProposeWithdrawal();
        vm.stopPrank();

        (
            address tokenToWithdraw,
            uint256 amountToWithdraw,
            address recipientToWithdraw,
            uint256 timeToWithdrawal
        ) = p2pSwap.getProposedWithdrawal();

        assertEq(tokenToWithdraw, address(0));
        assertEq(amountToWithdraw, 0);
        assertEq(recipientToWithdraw, address(0));
        assertEq(timeToWithdrawal, 0);
    }

    function test__unit_correct__acceptWithdrawal() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.sleep(4 hours);
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();

        (
            address tokenToWithdraw,
            uint256 amountToWithdraw,
            address recipientToWithdraw,
            uint256 timeToWithdrawal
        ) = p2pSwap.getProposedWithdrawal();

        assertEq(tokenToWithdraw, address(0));
        assertEq(amountToWithdraw, 0);
        assertEq(recipientToWithdraw, address(0));
        assertEq(timeToWithdrawal, 0);

        assertEq(p2pSwap.getBalanceOfContract(token), 0.1 ether - amount);
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, token),
            amount
        );
    }
}

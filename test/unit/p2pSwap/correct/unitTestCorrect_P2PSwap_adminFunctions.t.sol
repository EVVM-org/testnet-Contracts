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
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

contract unitTestCorrect_P2PSwap_adminFunctions is Test, Constants {
    address stableCoinAddress = makeAddr("stableCoin");

    function executeBeforeSetUp() internal override {}

    //░▒▓█ proposeAdmin ████████████████████████████████████████████████████████████▓▒░

    function test__unit_correct__proposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        assertEq(
            p2pSwap.getAdmin(),
            ADMIN.Address,
            "[admin]: admin should remain unchanged after proposal"
        );
        assertEq(
            p2pSwap.getAdminProposal(),
            COMMON_USER_NO_STAKER_1.Address,
            "[admin]: proposed admin should be set"
        );
        assertGt(
            p2pSwap.getAdminTimeToAccept(),
            block.timestamp,
            "[admin]: time to accept should be in the future"
        );
    }

    //░▒▓█ rejectProposalAdmin ████████████████████████████████████████████████████▓▒░

    function test__unit_correct__rejectProposalAdmin() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.warp(block.timestamp + 2 hours);
        p2pSwap.rejectProposalAdmin();
        vm.stopPrank();

        assertEq(
            p2pSwap.getAdmin(),
            ADMIN.Address,
            "[admin]: admin should remain unchanged after rejection"
        );
        assertEq(
            p2pSwap.getAdminProposal(),
            address(0),
            "[admin]: proposed admin should be cleared after rejection"
        );
        assertEq(
            p2pSwap.getAdminTimeToAccept(),
            0,
            "[admin]: time to accept should be 0 after rejection"
        );
    }

    //░▒▓█ acceptAdmin ████████████████████████████████████████████████████████████▓▒░

    function test__unit_correct__acceptAdmin() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        p2pSwap.acceptAdmin();
        vm.stopPrank();

        assertEq(
            p2pSwap.getAdmin(),
            COMMON_USER_NO_STAKER_1.Address,
            "[admin]: admin should be updated after acceptance"
        );
        assertEq(
            p2pSwap.getAdminProposal(),
            address(0),
            "[admin]: proposed admin should be cleared after acceptance"
        );
        assertEq(
            p2pSwap.getAdminTimeToAccept(),
            0,
            "[admin]: time to accept should be 0 after acceptance"
        );
    }

    //░▒▓█ proposeBasisPercentageFee ███████████████████████████████████████████████▓▒░

    function test__unit_correct__proposeBasisPercentageFee() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.stopPrank();

        assertEq(
            p2pSwap.getPercentageFee(),
            500,
            "[admin]: current fee should remain unchanged after proposal"
        );
        assertEq(
            p2pSwap.getPercentageFeeProposal(),
            300,
            "[admin]: proposed fee should be set"
        );
        assertGt(
            p2pSwap.getPercentageFeeTimeToAccept(),
            block.timestamp,
            "[admin]: time to accept should be in the future"
        );
    }

    //░▒▓█ rejectProposalBasisPercentageFee ████████████████████████████████████████▓▒░

    function test__unit_correct__rejectProposalBasisPercentageFee() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.warp(block.timestamp + 2 hours);
        p2pSwap.rejectProposalBasisPercentageFee();
        vm.stopPrank();

        assertEq(
            p2pSwap.getPercentageFee(),
            500,
            "[admin]: current fee should remain unchanged after rejection"
        );
        assertEq(
            p2pSwap.getPercentageFeeProposal(),
            0,
            "[admin]: proposed fee should be 0 after rejection"
        );
        assertEq(
            p2pSwap.getPercentageFeeTimeToAccept(),
            0,
            "[admin]: time to accept should be 0 after rejection"
        );
    }

    //░▒▓█ acceptBasisPercentageFee ████████████████████████████████████████████████▓▒░

    function test__unit_correct__acceptBasisPercentageFee() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.warp(block.timestamp + 1 days + 1);
        p2pSwap.acceptBasisPercentageFee();
        vm.stopPrank();

        assertEq(
            p2pSwap.getPercentageFee(),
            300,
            "[admin]: current fee should be updated after acceptance"
        );
        assertEq(
            p2pSwap.getPercentageFeeProposal(),
            0,
            "[admin]: proposed fee should be 0 after acceptance"
        );
        assertEq(
            p2pSwap.getPercentageFeeTimeToAccept(),
            0,
            "[admin]: time to accept should be 0 after acceptance"
        );
    }

    //░▒▓█ proposeBasisPointsForReward ████████████████████████████████████████████▓▒░

    function test__unit_correct__proposeBasisPointsForReward() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.stopPrank();

        P2PSwapStructs.Percentage memory currentBP = p2pSwap
            .getBasisPointsForReward();
        assertEq(currentBP.seller, 5000, "[admin]: current seller BP should remain 5000");
        assertEq(
            currentBP.service,
            4000,
            "[admin]: current service BP should remain 4000"
        );
        assertEq(
            currentBP.mateStaker,
            1000,
            "[admin]: current mateStaker BP should remain 1000"
        );

        P2PSwapStructs.Percentage memory proposedBP = p2pSwap
            .getBasisPointsForRewardProposal();
        assertEq(proposedBP.seller, 6000, "[admin]: proposed seller BP should be 6000");
        assertEq(
            proposedBP.service,
            3000,
            "[admin]: proposed service BP should be 3000"
        );
        assertEq(
            proposedBP.mateStaker,
            1000,
            "[admin]: proposed mateStaker BP should be 1000"
        );

        assertGt(
            p2pSwap.getBasisPointsForRewardProposalTime(),
            block.timestamp,
            "[admin]: proposal time should be in the future"
        );
    }

    //░▒▓█ rejectProposalBasisPointsForReward █████████████████████████████████████▓▒░

    function test__unit_correct__rejectProposalBasisPointsForReward() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.warp(block.timestamp + 2 hours);
        p2pSwap.rejectProposalBasisPointsForReward();
        vm.stopPrank();

        P2PSwapStructs.Percentage memory currentBP = p2pSwap
            .getBasisPointsForReward();
        assertEq(currentBP.seller, 5000, "[admin]: current seller BP should remain 5000");
        assertEq(
            currentBP.service,
            4000,
            "[admin]: current service BP should remain 4000"
        );
        assertEq(
            currentBP.mateStaker,
            1000,
            "[admin]: current mateStaker BP should remain 1000"
        );

        P2PSwapStructs.Percentage memory proposedBP = p2pSwap
            .getBasisPointsForRewardProposal();
        assertEq(proposedBP.seller, 0, "[admin]: proposed seller BP should be 0 after rejection");
        assertEq(
            proposedBP.service,
            0,
            "[admin]: proposed service BP should be 0 after rejection"
        );
        assertEq(
            proposedBP.mateStaker,
            0,
            "[admin]: proposed mateStaker BP should be 0 after rejection"
        );

        assertEq(
            p2pSwap.getBasisPointsForRewardProposalTime(),
            0,
            "[admin]: proposal time should be 0 after rejection"
        );
    }

    //░▒▓█ acceptBasisPointsForReward █████████████████████████████████████████████▓▒░

    function test__unit_correct__acceptBasisPointsForReward() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.warp(block.timestamp + 1 days + 1);
        p2pSwap.acceptBasisPointsForReward();
        vm.stopPrank();

        P2PSwapStructs.Percentage memory currentBP = p2pSwap
            .getBasisPointsForReward();
        assertEq(currentBP.seller, 6000, "[admin]: current seller BP should be updated to 6000");
        assertEq(
            currentBP.service,
            3000,
            "[admin]: current service BP should be updated to 3000"
        );
        assertEq(
            currentBP.mateStaker,
            1000,
            "[admin]: current mateStaker BP should be updated to 1000"
        );

        P2PSwapStructs.Percentage memory proposedBP = p2pSwap
            .getBasisPointsForRewardProposal();
        assertEq(proposedBP.seller, 0, "[admin]: proposed seller BP should be 0 after acceptance");
        assertEq(
            proposedBP.service,
            0,
            "[admin]: proposed service BP should be 0 after acceptance"
        );
        assertEq(
            proposedBP.mateStaker,
            0,
            "[admin]: proposed mateStaker BP should be 0 after acceptance"
        );

        assertEq(
            p2pSwap.getBasisPointsForRewardProposalTime(),
            0,
            "[admin]: proposal time should be 0 after acceptance"
        );
    }

    //░▒▓█ proposeWithdrawal █████████████████████████████████████████████████████▓▒░

    function test__unit_correct__proposeWithdrawal() external {
        AccountData memory seller = COMMON_USER_NO_STAKER_1;
        AccountData memory buyer = WILDCARD_USER;
        uint256 sellingPrice = 2000 * 10 ** 6;

        core.addBalance(seller.Address, ETHER_ADDRESS, 1 ether);

        _executeFn_p2pSwap_makeOrder(
            COMMON_USER_NO_STAKER_2,
            seller,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            sellingPrice,
            address(0),
            address(0),
            5001,
            0,
            6001
        );

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(sellingPrice);
        uint256 amountInMax = sellingPrice + feeAmount;
        core.addBalance(buyer.Address, stableCoinAddress, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
                buyer,
                ETHER_ADDRESS,
                stableCoinAddress,
                1,
                1 ether,
                amountInMax,
                address(0),
                address(0),
                7001,
                0,
                8001
            );

        vm.startPrank(buyer.Address, buyer.Address);
        p2pSwap.dispatchOrder(
            buyer.Address,
            ETHER_ADDRESS,
            stableCoinAddress,
            1,
            1 ether,
            amountInMax,
            address(0),
            address(0),
            7001,
            signature,
            0,
            8001,
            signaturePay
        );
        vm.stopPrank();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);
        assertGt(feesCollected, 0, "[noStaker/nPF]: fees should have been collected from the trade");

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected);
        vm.stopPrank();

        P2PSwapStructs.WithdrawalProposal memory wp = p2pSwap
            .getWithdrawalProposal();
        assertEq(
            wp.tokenToWithdraw,
            stableCoinAddress,
            "[admin]: withdrawal proposal token should be set"
        );
        assertEq(
            wp.amountToWithdraw,
            feesCollected,
            "[admin]: withdrawal proposal amount should be set"
        );
        assertGt(
            wp.proposalTime,
            block.timestamp,
            "[admin]: withdrawal proposal time should be in the future"
        );
    }

    //░▒▓█ rejectProposalWithdrawal ███████████████████████████████████████████████▓▒░

    function test__unit_correct__rejectProposalWithdrawal() external {
        AccountData memory seller = COMMON_USER_NO_STAKER_1;
        AccountData memory buyer = WILDCARD_USER;
        uint256 sellingPrice = 2000 * 10 ** 6;

        core.addBalance(seller.Address, ETHER_ADDRESS, 1 ether);

        _executeFn_p2pSwap_makeOrder(
            COMMON_USER_NO_STAKER_2,
            seller,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            sellingPrice,
            address(0),
            address(0),
            5001,
            0,
            6001
        );

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(sellingPrice);
        uint256 amountInMax = sellingPrice + feeAmount;
        core.addBalance(buyer.Address, stableCoinAddress, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
                buyer,
                ETHER_ADDRESS,
                stableCoinAddress,
                1,
                1 ether,
                amountInMax,
                address(0),
                address(0),
                7001,
                0,
                8001
            );

        vm.startPrank(buyer.Address, buyer.Address);
        p2pSwap.dispatchOrder(
            buyer.Address,
            ETHER_ADDRESS,
            stableCoinAddress,
            1,
            1 ether,
            amountInMax,
            address(0),
            address(0),
            7001,
            signature,
            0,
            8001,
            signaturePay
        );
        vm.stopPrank();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);
        assertGt(feesCollected, 0, "[noStaker/nPF]: fees should have been collected from the trade");

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected);
        vm.warp(block.timestamp + 2 hours);
        p2pSwap.rejectProposalWithdrawal();
        vm.stopPrank();

        P2PSwapStructs.WithdrawalProposal memory wp = p2pSwap
            .getWithdrawalProposal();
        assertEq(
            wp.tokenToWithdraw,
            address(0),
            "[admin]: withdrawal proposal token should be cleared after rejection"
        );
        assertEq(
            wp.amountToWithdraw,
            0,
            "[admin]: withdrawal proposal amount should be 0 after rejection"
        );
        assertEq(
            wp.proposalTime,
            0,
            "[admin]: withdrawal proposal time should be 0 after rejection"
        );
    }

    //░▒▓█ acceptWithdrawal ██████████████████████████████████████████████████████▓▒░

    function test__unit_correct__acceptWithdrawal() external {
        AccountData memory seller = COMMON_USER_NO_STAKER_1;
        AccountData memory buyer = WILDCARD_USER;
        uint256 sellingPrice = 2000 * 10 ** 6;

        core.addBalance(seller.Address, ETHER_ADDRESS, 1 ether);

        _executeFn_p2pSwap_makeOrder(
            COMMON_USER_NO_STAKER_2,
            seller,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            sellingPrice,
            address(0),
            address(0),
            1001,
            0,
            2001
        );

        uint256 feeAmount = p2pSwap.getFeePaymentAmount(sellingPrice);
        uint256 amountInMax = sellingPrice + feeAmount;
        core.addBalance(buyer.Address, stableCoinAddress, amountInMax);

        (
            bytes memory signature,
            bytes memory signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
                buyer,
                ETHER_ADDRESS,
                stableCoinAddress,
                1,
                1 ether,
                amountInMax,
                address(0),
                address(0),
                3001,
                0,
                4001
            );

        vm.startPrank(buyer.Address, buyer.Address);
        p2pSwap.dispatchOrder(
            buyer.Address,
            ETHER_ADDRESS,
            stableCoinAddress,
            1,
            1 ether,
            amountInMax,
            address(0),
            address(0),
            3001,
            signature,
            0,
            4001,
            signaturePay
        );
        vm.stopPrank();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);
        assertGt(feesCollected, 0, "[noStaker/nPF]: fees should have been collected from the trade");

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected);
        vm.warp(block.timestamp + 1 days + 1);
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();

        P2PSwapStructs.WithdrawalProposal memory wp = p2pSwap
            .getWithdrawalProposal();
        assertEq(
            wp.tokenToWithdraw,
            address(0),
            "[admin]: withdrawal proposal token should be cleared after acceptance"
        );
        assertEq(
            wp.amountToWithdraw,
            0,
            "[admin]: withdrawal proposal amount should be 0 after acceptance"
        );
        assertEq(
            wp.proposalTime,
            0,
            "[admin]: withdrawal proposal time should be 0 after acceptance"
        );

        assertEq(
            p2pSwap.getTotalFeesCollected(stableCoinAddress),
            0,
            "[admin]: fees collected should be 0 after withdrawal"
        );
    }
}

// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   __\/ __ \ /  ___\   __\
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
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import {
    P2PSwapError
} from "@evvm/testnet-contracts/library/errors/P2PSwapError.sol";

contract unitTestRevert_P2PSwap_adminFunctions is Test, Constants {
    address stableCoinAddress = makeAddr("stableCoin");

    function executeBeforeSetUp() internal override {}

    //░▒▓█ proposeAdmin ████████████████████████████████████████████████████████████▓▒░

    function test__unit_revert__proposeAdmin__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_2.Address);
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__IncorrectAddressInput_zero()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.IncorrectAddressInput.selector);
        p2pSwap.proposeAdmin(address(0));
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__IncorrectAddressInput_currentAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.IncorrectAddressInput.selector);
        p2pSwap.proposeAdmin(ADMIN.Address);
        vm.stopPrank();
    }

    //░▒▓█ rejectProposalAdmin ████████████████████████████████████████████████████▓▒░

    function test__unit_revert__rejectProposalAdmin__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.rejectProposalAdmin();
        vm.stopPrank();
    }

    //░▒▓█ acceptAdmin ████████████████████████████████████████████████████████████▓▒░

    function test__unit_revert__acceptAdmin__ProposalNotReadyToAccept() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.ProposalNotReadyToAccept.selector);
        p2pSwap.acceptAdmin();
        vm.stopPrank();
    }

    function test__unit_revert__acceptAdmin__SenderIsNotTheProposedAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        skip(1 days + 1);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotTheProposedAdmin.selector);
        p2pSwap.acceptAdmin();
        vm.stopPrank();
    }

    //░▒▓█ proposeBasisPercentageFee ███████████████████████████████████████████████▓▒░

    function test__unit_revert__proposeBasisPercentageFee__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.stopPrank();
    }

    function test__unit_revert__proposeBasisPercentageFee__IncorrectAddressInput()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.IncorrectAddressInput.selector);
        p2pSwap.proposeBasisPercentageFee(10_001);
        vm.stopPrank();
    }

    //░▒▓█ rejectProposalBasisPercentageFee ████████████████████████████████████████▓▒░

    function test__unit_revert__rejectProposalBasisPercentageFee__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.rejectProposalBasisPercentageFee();
        vm.stopPrank();
    }

    //░▒▓█ acceptBasisPercentageFee ████████████████████████████████████████████████▓▒░

    function test__unit_revert__acceptBasisPercentageFee__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.stopPrank();

        skip(1 days + 1);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.acceptBasisPercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptBasisPercentageFee__ProposalNotReadyToAccept()
        external
    {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPercentageFee(300);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.ProposalNotReadyToAccept.selector);
        p2pSwap.acceptBasisPercentageFee();
        vm.stopPrank();
    }

    //░▒▓█ proposeBasisPointsForReward ████████████████████████████████████████████▓▒░

    function test__unit_revert__proposeBasisPointsForReward__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.stopPrank();
    }

    function test__unit_revert__proposeBasisPointsForReward__InvalidBasisPoints()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.InvalidBasisPoints.selector);
        p2pSwap.proposeBasisPointsForReward(5000, 3000, 1000);
        vm.stopPrank();
    }

    //░▒▓█ rejectProposalBasisPointsForReward █████████████████████████████████████▓▒░

    function test__unit_revert__rejectProposalBasisPointsForReward__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.rejectProposalBasisPointsForReward();
        vm.stopPrank();
    }

    //░▒▓█ acceptBasisPointsForReward █████████████████████████████████████████████▓▒░

    function test__unit_revert__acceptBasisPointsForReward__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.stopPrank();

        skip(1 days + 1);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.acceptBasisPointsForReward();
        vm.stopPrank();
    }

    function test__unit_revert__acceptBasisPointsForReward__ProposalNotReadyToAccept()
        external
    {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeBasisPointsForReward(6000, 3000, 1000);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.ProposalNotReadyToAccept.selector);
        p2pSwap.acceptBasisPointsForReward();
        vm.stopPrank();
    }

    //░▒▓█ proposeWithdrawal █████████████████████████████████████████████████████▓▒░

    function _generateFees() private {
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
    }

    function test__unit_revert__proposeWithdrawal__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.proposeWithdrawal(stableCoinAddress, 100);
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal__IncorrectInput() external {
        _generateFees();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.IncorrectInput.selector);
        p2pSwap.proposeWithdrawal(stableCoinAddress, 0);
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal__InsufficientAmount() external {
        _generateFees();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.InsufficientAmount.selector);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected + 1);
        vm.stopPrank();
    }

    //░▒▓█ rejectProposalWithdrawal ███████████████████████████████████████████████▓▒░

    function test__unit_revert__rejectProposalWithdrawal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.rejectProposalWithdrawal();
        vm.stopPrank();
    }

    //░▒▓█ acceptWithdrawal ██████████████████████████████████████████████████████▓▒░

    function test__unit_revert__acceptWithdrawal__SenderIsNotAdmin() external {
        _generateFees();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected);
        vm.stopPrank();

        skip(1 days + 1);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(P2PSwapError.SenderIsNotAdmin.selector);
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptWithdrawal__ProposalNotReadyToAccept()
        external
    {
        _generateFees();

        uint256 feesCollected = p2pSwap.getTotalFeesCollected(stableCoinAddress);

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeWithdrawal(stableCoinAddress, feesCollected);
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(P2PSwapError.ProposalNotReadyToAccept.selector);
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }
}

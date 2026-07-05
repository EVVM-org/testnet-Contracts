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
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_P2PSwap_cancelOrder is Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    struct CancelOrderInputs {
        address offeredToken;
        address requestedToken;
        uint256 orderId;
        address senderExecutor;
        address originExecutor;
        uint256 nonce;
        bytes signature;
        uint256 priorityFeePay;
        uint256 noncePay;
        bytes signaturePay;
    }

    AccountData USER = COMMON_USER_NO_STAKER_1;
    Fisher fisher =
        Fisher({noStaker: COMMON_USER_NO_STAKER_2, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function executeBeforeSetUp() internal override {
        core.addBalance(USER.Address, ETHER_ADDRESS, 2 ether);
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            address(0),
            address(0),
            67676767676767676767676767676767676767676767676767676767676767676767,
            0,
            420420420420420420420420420420420420420420420420420420420420420420
        );
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            2000 * 10 ** 6,
            address(0),
            address(0),
            5318008,
            0,
            58008
        );
    }

    function test__unit_revert__cancelOrder__OrderIsUnavailable() external {
        CancelOrderInputs memory inputs = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 99,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.OrderIsUnavailable.selector);
        p2pSwap.cancelOrder(
            USER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.signature,
            inputs.priorityFeePay,
            inputs.noncePay,
            inputs.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__cancelOrder__NotTheSeller() external {
        CancelOrderInputs memory inputs = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.NotTheSeller.selector);
        p2pSwap.cancelOrder(
            /* 🢃 Diferent user (not the seller) 🢃 */
            fisher.noStaker.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.signature,
            inputs.priorityFeePay,
            inputs.noncePay,
            inputs.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__cancelOrder__InvalidSignature_offeredToken()
        external
    {
        CancelOrderInputs memory inputs = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            /* 🢃 Diferent offeredToken 🢃 */
            address(67),
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.cancelOrder(
            USER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.signature,
            inputs.priorityFeePay,
            inputs.noncePay,
            inputs.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__cancelOrder__InvalidSignature_requestedToken()
        external
    {
        CancelOrderInputs memory inputs = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputs.offeredToken,
            /* 🢃 Diferent requestedToken 🢃 */
            address(67),
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.cancelOrder(
            USER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.signature,
            inputs.priorityFeePay,
            inputs.noncePay,
            inputs.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__cancelOrder__InvalidSignature_orderId()
        external
    {
        CancelOrderInputs memory inputs = CancelOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 67,
            signature: hex"",
            priorityFeePay: 0,
            noncePay: 78,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_cancelOrder(
            USER,
            inputs.offeredToken,
            inputs.requestedToken,
            /* 🢃 Diferent orderId 🢃 */
            67,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.cancelOrder(
            USER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.signature,
            inputs.priorityFeePay,
            inputs.noncePay,
            inputs.signaturePay
        );
        vm.stopPrank();
    }
}

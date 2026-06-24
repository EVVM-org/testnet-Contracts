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

contract unitTestRevert_P2PSwap_dispatchOrder is Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    struct DispatchOrderInputs {
        address offeredToken;
        address requestedToken;
        uint256 orderId;
        uint256 amountOut;
        uint256 amountInMax;
        address senderExecutor;
        address originExecutor;
        uint256 nonce;
        bytes signature;
        uint256 priorityFeePay;
        uint256 noncePay;
        bytes signaturePay;
    }

    uint256 constant SELLING_PRICE = 2000 * 10 ** 6;

    AccountData BUYER = WILDCARD_USER;
    AccountData SELLER = COMMON_USER_NO_STAKER_1;
    Fisher fisher =
        Fisher({noStaker: COMMON_USER_NO_STAKER_2, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function _addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function executeBeforeSetUp() internal override {
        core.addBalance(SELLER.Address, ETHER_ADDRESS, 2 ether);
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            SELLER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            SELLING_PRICE,
            address(0),
            address(0),
            67676767676767676767676767676767676767676767676767676767676767676767,
            0,
            420420420420420420420420420420420420420420420420420420420420420420
        );
        _executeFn_p2pSwap_makeOrder(
            fisher.noStaker,
            SELLER,
            ETHER_ADDRESS,
            stableCoinAddress,
            1 ether,
            SELLING_PRICE,
            address(0),
            address(0),
            5318008,
            0,
            58008
        );
    }

    function test__unit_revert__dispatchOrder__ZeroAmount_amountOut() external {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 0,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.ZeroAmount.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__ZeroAmount_amountInMax() external {
        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: 0,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.ZeroAmount.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__OrderIsUnavailable() external {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 99,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.OrderIsUnavailable.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InsufficientAmountToFill()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 2 ether,
            amountInMax: (SELLING_PRICE * 2) + (feeAmount * 2),
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.InsufficientAmountToFill.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InsufficientPayment() external {
        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: 1,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.InsufficientPayment.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InvalidSignature_offeredToken()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            /* 🢃 Diferent offeredToken 🢃 */
            address(67),
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InvalidSignature_requestedToken()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            /* 🢃 Diferent requestedToken 🢃 */
            address(67),
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InvalidSignature_orderId()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            /* 🢃 Diferent orderId 🢃 */
            67,
            inputs.amountOut,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InvalidSignature_amountOut()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            /* 🢃 Diferent amountOut 🢃 */
            0.5 ether,
            inputs.amountInMax,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

    function test__unit_revert__dispatchOrder__InvalidSignature_amountInMax()
        external
    {
        uint256 feeAmount = p2pSwap.getFeePaymentAmount(SELLING_PRICE);

        DispatchOrderInputs memory inputs = DispatchOrderInputs({
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            orderId: 1,
            amountOut: 1 ether,
            amountInMax: SELLING_PRICE + feeAmount,
            senderExecutor: address(0),
            originExecutor: address(0),
            signature: hex"",
            nonce: 10001,
            priorityFeePay: 0,
            noncePay: 10002,
            signaturePay: hex""
        });

        _addBalance(BUYER, stableCoinAddress, inputs.amountInMax);

        (
            inputs.signature,
            inputs.signaturePay
        ) = _executeSig_p2pSwap_dispatchOrder(
            BUYER,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            /* 🢃 Diferent amountInMax 🢃 */
            SELLING_PRICE,
            inputs.senderExecutor,
            inputs.originExecutor,
            inputs.nonce,
            inputs.priorityFeePay,
            inputs.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.dispatchOrder(
            BUYER.Address,
            inputs.offeredToken,
            inputs.requestedToken,
            inputs.orderId,
            inputs.amountOut,
            inputs.amountInMax,
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

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
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import {
    P2PSwapError
} from "@evvm/testnet-contracts/library/errors/P2PSwapError.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_P2PSwap_makeOrder is Test, Constants {
    struct Fisher {
        AccountData noStaker;
        AccountData staker;
    }

    struct MakeOrderInputs {
        AccountData user;
        address offeredToken;
        address requestedToken;
        uint256 offeredAmount;
        uint256 requestedAmount;
        address senderExecutor;
        address originExecutor;
        uint256 nonce;
        bytes signature;
        uint256 priorityFeePay;
        uint256 noncePay;
        bytes signaturePay;
    }

    Fisher fisher =
        Fisher({noStaker: COMMON_USER_NO_STAKER_1, staker: COMMON_USER_STAKER});

    address stableCoinAddress = makeAddr("stableCoin");

    function executeBeforeSetUp() internal override {}

    function addBalance(
        AccountData memory user,
        address token,
        uint256 amount
    ) private {
        core.addBalance(user.Address, token, amount);
    }

    function test__unit_revert__makeOrder__ZeroAmount_offeredAmount() external {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.ZeroAmount.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__ZeroAmount_requestedAmount()
        external
    {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 0,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.ZeroAmount.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__SameTokenPair() external {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: ETHER_ADDRESS,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(P2PSwapError.SameTokenPair.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__InvalidSignature_offeredToken()
        external
    {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            /* 🢃 Diferent offeredToken 🢃 */
            address(67),
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__InvalidSignature_requestedToken()
        external
    {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            /* 🢃 Diferent requestedToken 🢃 */
            address(67),
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__InvalidSignature_offeredAmount()
        external
    {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            /* 🢃 Diferent offeredAmount 🢃 */
            67676767,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__makeOrder__InvalidSignature_requestedAmount()
        external
    {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 14569,
            signature: "",
            priorityFeePay: 0,
            noncePay: 45546564,
            signaturePay: ""
        });

        addBalance(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.offeredAmount + inputsNoPF.priorityFeePay
        );

        (
            inputsNoPF.signature,
            inputsNoPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsNoPF.user,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            inputsNoPF.requestedAmount,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        p2pSwap.makeOrder(
            inputsNoPF.user.Address,
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken,
            inputsNoPF.offeredAmount,
            /* 🢃 Diferent requestedAmount 🢃 */
            67676767,
            inputsNoPF.senderExecutor,
            inputsNoPF.originExecutor,
            inputsNoPF.nonce,
            inputsNoPF.signature,
            inputsNoPF.priorityFeePay,
            inputsNoPF.noncePay,
            inputsNoPF.signaturePay
        );
        vm.stopPrank();
    }
}

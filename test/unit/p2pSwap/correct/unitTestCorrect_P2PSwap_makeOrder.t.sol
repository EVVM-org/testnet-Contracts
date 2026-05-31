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

contract unitTestCorrect_P2PSwap_makeOrder is Constants {
    

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

    function test__unit_correct__makeOrder() external {
        MakeOrderInputs memory inputsNoPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.001 ether,
            requestedAmount: 1000 * 10**6,
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
            inputsNoPF.offeredAmount
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

        bytes32 marketId = p2pSwap.getMarketId(
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken
        );

        P2PSwapStructs.Order memory order = p2pSwap.getOrder(
            marketId,
            0
        );

        assertEq(
            order.seller,
            inputsNoPF.user.Address,
            "Error: incorrect seller in order"
        );
        assertEq(
            order.offeredAmount,
            inputsNoPF.offeredAmount,
            "Error: incorrect offered amount in order"
        );
        assertEq(
            order.requestedAmount,
            inputsNoPF.requestedAmount,
            "Error: incorrect requested amount in order"
        );
        assertEq(
            order.amountAvailable,
            inputsNoPF.offeredAmount,
            "Error: incorrect amount available in order"
        );

        assertEq(
            core.getBalance(inputsNoPF.user.Address, inputsNoPF.offeredToken),
            0,
            "Error: incorrect user balance after makeOrder"
        );

        assertEq(
            core.getBalance(address(p2pSwap), inputsNoPF.offeredToken),
            inputsNoPF.offeredAmount,
            "Error: incorrect p2pSwap balance after makeOrder"
        );
        vm.stopPrank();
    }
}

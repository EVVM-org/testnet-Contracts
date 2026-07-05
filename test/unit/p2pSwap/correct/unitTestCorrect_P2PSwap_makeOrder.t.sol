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

contract unitTestCorrect_P2PSwap_makeOrder is Test, Constants {
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

    function test__unit_correct__makeOrder__noStaker() external {
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

        bytes32 marketIdNoPF = p2pSwap.getMarketId(
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken
        );

        P2PSwapStructs.Order memory orderNoPF = p2pSwap.getOrder(
            marketIdNoPF,
            1
        );

        assertEq(
            orderNoPF.seller,
            inputsNoPF.user.Address,
            "[noStaker/nPF]: incorrect seller in order"
        );
        assertEq(
            orderNoPF.offeredAmount,
            inputsNoPF.offeredAmount,
            "[noStaker/nPF]: incorrect offered amount in order"
        );
        assertEq(
            orderNoPF.requestedAmount,
            inputsNoPF.requestedAmount,
            "[noStaker/nPF]: incorrect requested amount in order"
        );
        assertEq(
            orderNoPF.amountAvailable,
            inputsNoPF.offeredAmount,
            "[noStaker/nPF]: incorrect amount available in order"
        );

        assertEq(
            core.getBalance(inputsNoPF.user.Address, inputsNoPF.offeredToken),
            0,
            "[noStaker/nPF]: incorrect user balance after makeOrder"
        );

        assertEq(
            core.getBalance(address(p2pSwap), inputsNoPF.offeredToken),
            inputsNoPF.offeredAmount,
            "[noStaker/nPF]: incorrect p2pSwap balance after makeOrder"
        );

        assertEq(
            core.getBalance(fisher.noStaker.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "[noStaker/nPF]: fisher should not receive any reward when making order"
        );

        assertEq(
            core.getBalance(fisher.noStaker.Address, inputsNoPF.offeredToken),
            0,
            "[noStaker/nPF]: fisher should not receive any priorityFee when making order"
        );

        MakeOrderInputs memory inputsPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.007 ether,
            requestedAmount: 3000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 12312432,
            signature: "",
            priorityFeePay: 1 * 10 ** 6,
            noncePay: 3454353,
            signaturePay: ""
        });

        (
            inputsPF.signature,
            inputsPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsPF.user,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.offeredAmount,
            inputsPF.requestedAmount,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.priorityFeePay,
            inputsPF.noncePay
        );

        addBalance(
            inputsPF.user,
            inputsPF.offeredToken,
            inputsPF.offeredAmount + inputsPF.priorityFeePay
        );

        vm.startPrank(fisher.noStaker.Address, fisher.noStaker.Address);
        p2pSwap.makeOrder(
            inputsPF.user.Address,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.offeredAmount,
            inputsPF.requestedAmount,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.signature,
            inputsPF.priorityFeePay,
            inputsPF.noncePay,
            inputsPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPF = p2pSwap.getMarketId(
            inputsPF.offeredToken,
            inputsPF.requestedToken
        );

        P2PSwapStructs.Order memory orderPF = p2pSwap.getOrder(marketIdPF, 2);

        assertEq(
            orderPF.seller,
            inputsPF.user.Address,
            "[noStaker/PF]: incorrect seller in order"
        );
        assertEq(
            orderPF.offeredAmount,
            inputsPF.offeredAmount,
            "[noStaker/PF]: incorrect offered amount in order"
        );
        assertEq(
            orderPF.requestedAmount,
            inputsPF.requestedAmount,
            "[noStaker/PF]: incorrect requested amount in order"
        );
        assertEq(
            orderPF.amountAvailable,
            inputsPF.offeredAmount,
            "[noStaker/PF]: incorrect amount available in order"
        );

        assertEq(
            core.getBalance(inputsPF.user.Address, inputsPF.offeredToken),
            0,
            "[noStaker/PF]: incorrect user balance after makeOrder"
        );

        assertEq(
            core.getBalance(address(p2pSwap), inputsPF.offeredToken),
            inputsPF.offeredAmount +
                inputsNoPF.offeredAmount +
                p2pSwap.getTotalFeesCollected(inputsPF.offeredToken),
            "[noStaker/PF]: incorrect p2pSwap balance after makeOrder"
        );

        assertEq(
            core.getBalance(fisher.noStaker.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "[noStaker/PF]: fisher should not receive any reward when making order"
        );

        assertEq(
            core.getBalance(fisher.noStaker.Address, inputsPF.offeredToken),
            0,
            "[noStaker/PF]: fisher should not receive any priorityFee when making order"
        );
    }

    function test__unit_correct__makeOrder__staker() external {
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

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
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

        bytes32 marketIdNoPF = p2pSwap.getMarketId(
            inputsNoPF.offeredToken,
            inputsNoPF.requestedToken
        );

        P2PSwapStructs.Order memory orderNoPF = p2pSwap.getOrder(
            marketIdNoPF,
            1
        );

        assertEq(
            orderNoPF.seller,
            inputsNoPF.user.Address,
            "[staker/nPF]: incorrect seller in order"
        );
        assertEq(
            orderNoPF.offeredAmount,
            inputsNoPF.offeredAmount,
            "[staker/nPF]: incorrect offered amount in order"
        );
        assertEq(
            orderNoPF.requestedAmount,
            inputsNoPF.requestedAmount,
            "[staker/nPF]: incorrect requested amount in order"
        );
        assertEq(
            orderNoPF.amountAvailable,
            inputsNoPF.offeredAmount,
            "[staker/nPF]: incorrect amount available in order"
        );

        assertEq(
            core.getBalance(inputsNoPF.user.Address, inputsNoPF.offeredToken),
            0,
            "[staker/nPF]: incorrect user balance after makeOrder"
        );

        assertEq(
            core.getBalance(address(p2pSwap), inputsNoPF.offeredToken),
            inputsNoPF.offeredAmount,
            "[staker/nPF]: incorrect p2pSwap balance after makeOrder"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount(),
            "[staker/nPF]: fisher should receive 1 reward when making order"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, inputsNoPF.offeredToken),
            inputsNoPF.priorityFeePay,
            "[staker/nPF]: fisher should not receive priorityFee of 0 when making order"
        );

        MakeOrderInputs memory inputsPF = MakeOrderInputs({
            user: COMMON_USER_NO_STAKER_1,
            offeredToken: ETHER_ADDRESS,
            requestedToken: stableCoinAddress,
            offeredAmount: 0.007 ether,
            requestedAmount: 3000 * 10 ** 6,
            senderExecutor: address(0),
            originExecutor: address(0),
            nonce: 12312432,
            signature: "",
            priorityFeePay: 1 * 10 ** 6,
            noncePay: 3454353,
            signaturePay: ""
        });

        (
            inputsPF.signature,
            inputsPF.signaturePay
        ) = _executeSig_p2pSwap_makeOrder(
            inputsPF.user,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.offeredAmount,
            inputsPF.requestedAmount,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.priorityFeePay,
            inputsPF.noncePay
        );

        addBalance(
            inputsPF.user,
            inputsPF.offeredToken,
            inputsPF.offeredAmount + inputsPF.priorityFeePay
        );

        vm.startPrank(fisher.staker.Address, fisher.staker.Address);
        p2pSwap.makeOrder(
            inputsPF.user.Address,
            inputsPF.offeredToken,
            inputsPF.requestedToken,
            inputsPF.offeredAmount,
            inputsPF.requestedAmount,
            inputsPF.senderExecutor,
            inputsPF.originExecutor,
            inputsPF.nonce,
            inputsPF.signature,
            inputsPF.priorityFeePay,
            inputsPF.noncePay,
            inputsPF.signaturePay
        );
        vm.stopPrank();

        bytes32 marketIdPF = p2pSwap.getMarketId(
            inputsPF.offeredToken,
            inputsPF.requestedToken
        );

        P2PSwapStructs.Order memory orderPF = p2pSwap.getOrder(marketIdPF, 2);

        assertEq(
            orderPF.seller,
            inputsPF.user.Address,
            "[staker/PF]: incorrect seller in order"
        );
        assertEq(
            orderPF.offeredAmount,
            inputsPF.offeredAmount,
            "[staker/PF]: incorrect offered amount in order"
        );
        assertEq(
            orderPF.requestedAmount,
            inputsPF.requestedAmount,
            "[staker/PF]: incorrect requested amount in order"
        );
        assertEq(
            orderPF.amountAvailable,
            inputsPF.offeredAmount,
            "[staker/PF]: incorrect amount available in order"
        );

        assertEq(
            core.getBalance(inputsPF.user.Address, inputsPF.offeredToken),
            0,
            "[staker/PF]: incorrect user balance after makeOrder"
        );

        assertEq(
            core.getBalance(address(p2pSwap), inputsPF.offeredToken),
            inputsPF.offeredAmount +
                inputsNoPF.offeredAmount +
                p2pSwap.getTotalFeesCollected(inputsPF.offeredToken),
            "[staker/PF]: incorrect p2pSwap balance after makeOrder"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount() * 2,
            "[staker/PF]: fisher should receive 2 rewards when making order"
        );

        assertEq(
            core.getBalance(fisher.staker.Address, inputsPF.offeredToken),
            inputsPF.priorityFeePay + inputsNoPF.priorityFeePay,
            "[staker/PF]: fisher should receive the correct priorityFee when making order"
        );
    }
}

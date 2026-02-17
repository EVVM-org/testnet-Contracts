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
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

contract unitTestRevert_P2PSwap_cancelOrder is Test, Constants {
    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }

    /// @notice Creates an order for testing purposes
    function createOrder(
        AccountData memory executor,
        AccountData memory user,
        uint256 nonceP2PSwap,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 priorityFee,
        uint256 noncePay
    ) private returns (uint256 market, uint256 orderId) {
        P2PSwapStructs.MetadataMakeOrder memory orderData = P2PSwapStructs
            .MetadataMakeOrder({
                nonce: nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                amountA: amountA,
                amountB: amountB
            });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                amountA,
                amountB
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(executor.Address);
        (market, orderId) = p2pSwap.makeOrder(
            user.Address,
            orderData,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_revert__cancelOrder_invalidSignature() external {
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;

        // Fund user1 with amountA
        addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, amountA);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            priorityFee,
            noncePay
        );

        nonceP2PSwap = 5453;

        assertEq(market, 1);
        assertEq(orderId, 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForCancelOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenA, // tokenA twice here
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        P2PSwapStructs.MetadataCancelOrder memory orderData = P2PSwapStructs
            .MetadataCancelOrder({
                nonce: nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.cancelOrder(
            COMMON_USER_NO_STAKER_1.Address,
            orderData,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0
        );
        assertEq(core.getBalance(address(p2pSwap), ETHER_ADDRESS), amountA);
    }

    function test__unit_revert__cancelOrder_invalidNonce() external {
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;
        

        // Fund user1 with amountA
        addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, amountA);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            priorityFee,
            noncePay
        );

        // nonceP2PSwap = 5453; // we don't change the nonce, thus reverting

        assertEq(market, 1);
        assertEq(orderId, 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForCancelOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        P2PSwapStructs.MetadataCancelOrder memory orderData = P2PSwapStructs
            .MetadataCancelOrder({
                nonce: nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.cancelOrder(
            COMMON_USER_NO_STAKER_1.Address,
            orderData,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0
        );
        assertEq(core.getBalance(address(p2pSwap), ETHER_ADDRESS), amountA);
    }

    function test__unit_revert__cancelOrder_invalidOrder() external {
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;
        

        // Fund user1 with amountA
        addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, amountA);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForCancelOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                1 // fake orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        P2PSwapStructs.MetadataCancelOrder memory orderData = P2PSwapStructs
            .MetadataCancelOrder({
                nonce: nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: 1,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.cancelOrder(
            COMMON_USER_NO_STAKER_1.Address,
            orderData,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__cancelOrder_invalidPay() external {
        // of the priority fees
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0.0001 ether;
        uint256 noncePay = 0;
        

        // Fund user1 with amountA + priorityFee
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            amountA + (priorityFee * 2)
        );
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            priorityFee,
            noncePay
        );

        nonceP2PSwap = 5453;

        assertEq(market, 1);
        assertEq(orderId, 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForCancelOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay, // we use the same nonce here
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.cancelOrder(
            COMMON_USER_NO_STAKER_1.Address,
            P2PSwapStructs.MetadataCancelOrder({
                nonce: nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                signature: signatureP2P
            }),
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee
        );
        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee
        );
        assertEq(core.getBalance(address(p2pSwap), ETHER_ADDRESS), amountA);
    }
}

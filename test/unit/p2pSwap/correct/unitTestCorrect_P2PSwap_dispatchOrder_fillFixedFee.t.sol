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
import "forge-std/console.sol";

import {Constants} from "test/Constants.sol";

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

contract unitTestCorrect_P2PSwap_dispatchOrder_fillFixedFee is Test, Constants {
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
        // build P2P signature
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

        // build payment signature
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
            tokenA,
            tokenB,
            amountA,
            amountB,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_correct__dispatchOrder_fillFixedFee_proportionalFee_payAsync_noPriorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 43231;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        // 2. create an order
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

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
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

        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
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
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillFixedFee_proportionalFee_payAsync_priorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0.0001 ether;
        uint256 noncePay = 5689589;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            tokenA,
            amountA + priorityFee
        );
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            amountB + fee + priorityFee
        );
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        // 2. create an order
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

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
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

        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
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
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillFixedFee_fixedFee_payAsync_noPriorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 4121;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.0004 ether; // smaller than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        // 2. create an order
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

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
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

        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
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
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillFixedFee_fixedFee_payAsync_priorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0.0001 ether;
        uint256 noncePay = 54423;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.0004 ether; // smaller than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            tokenA,
            amountA + priorityFee
        );
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            amountB + fee + priorityFee
        );
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

        // 2. create an order
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

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
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

        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
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
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );
    }
}

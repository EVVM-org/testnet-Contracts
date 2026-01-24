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

import {Constants, TestERC20} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_Treasury_withdraw is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        testToken = new TestERC20();
    }

    function depositHostNative(
        AccountData memory user,
        uint256 amount
    ) internal {
        vm.deal(user.Address, amount);

        vm.startPrank(user.Address);

        treasury.deposit{value: amount}(address(0), amount);

        vm.stopPrank();
    }

    function depositToken(AccountData memory user, uint256 amount) internal {
        testToken.mint(user.Address, amount);

        vm.startPrank(user.Address);

        testToken.approve(address(treasury), amount);

        treasury.deposit(address(testToken), amount);

        vm.stopPrank();
    }

    function test__unit_correct__withdraw__hostNative() external {
        depositHostNative(COMMON_USER_NO_STAKER_1, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        treasury.withdraw(address(0), 0.01 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0
        );

        assertEq(COMMON_USER_NO_STAKER_1.Address.balance, 0.01 ether);

        assertEq(address(treasury).balance, 0);
    }

    function test__unit_correct__withdraw__token() external {
        depositToken(COMMON_USER_NO_STAKER_1, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        treasury.withdraw(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            0
        );

        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            10 ether
        );
        assertEq(testToken.balanceOf(address(treasury)), 0);
    }
}

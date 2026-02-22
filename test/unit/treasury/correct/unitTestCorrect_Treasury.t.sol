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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract unitTestCorrect_Treasury is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        testToken = new TestERC20();
    }

    function test__unit_correct__deposit__hostNative() external {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        treasury.deposit{value: 0.01 ether}(address(0), 0.01 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0.01 ether,
            "Error: incorrect balance after deposit"
        );
        assertEq(
            address(treasury).balance,
            0.01 ether,
            "Error: incorrect treasury balance after deposit"
        );
        assertEq(
            COMMON_USER_NO_STAKER_1.Address.balance,
            0 ether,
            "Error: incorrect user balance after deposit"
        );
    }

    function test__unit_correct__deposit__token() external {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            10 ether,
            "Error: incorrect balance after deposit"
        );
        assertEq(
            testToken.balanceOf(address(treasury)),
            10 ether,
            "Error: incorrect treasury token balance after deposit"
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            0,
            "Error: incorrect user token balance after deposit"
        );
    }

    function test__unit_correct__withdraw__hostNative() external {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        treasury.deposit{value: 0.01 ether}(address(0), 0.01 ether);

        treasury.withdraw(address(0), 0.01 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0 ether,
            "Error: incorrect balance after withdraw"
        );
        assertEq(
            address(treasury).balance,
            0 ether,
            "Error: incorrect treasury balance after withdraw"
        );
        assertEq(
            COMMON_USER_NO_STAKER_1.Address.balance,
            0.01 ether,
            "Error: incorrect user balance after withdraw"
        );
    }

    function test__unit_correct__withdraw__token() external {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);
        treasury.deposit(address(testToken), 10 ether);
        treasury.withdraw(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            0,
            "Error: incorrect balance after withdraw"
        );
        assertEq(
            testToken.balanceOf(address(treasury)),
            0,
            "Error: incorrect treasury token balance after withdraw"
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            10 ether,
            "Error: incorrect user token balance after withdraw"
        );
    }

    function test__unit_correct__deposit__denyList() external {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x02); // Activate denyList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        vm.stopPrank();

        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            10 ether,
            "Error: incorrect balance after deposit"
        );
        assertEq(
            testToken.balanceOf(address(treasury)),
            10 ether,
            "Error: incorrect treasury token balance after deposit"
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            0,
            "Error: incorrect user token balance after deposit"
        );
    }

    function test__unit_correct__deposit__allowList() external {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01); // Activate allowList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        core.setTokenStatusOnAllowList(address(testToken), true);
        vm.stopPrank();

        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            10 ether,
            "Error: incorrect balance after deposit"
        );
        assertEq(
            testToken.balanceOf(address(treasury)),
            10 ether,
            "Error: incorrect treasury token balance after deposit"
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            0,
            "Error: incorrect user token balance after deposit"
        );
    }
}

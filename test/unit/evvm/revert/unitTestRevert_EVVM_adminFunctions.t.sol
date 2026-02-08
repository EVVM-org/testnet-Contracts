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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestRevert_EVVM_adminFunctions is Test, Constants {
    Evvm public evvmMock;
    AccountData COMMON_USER = WILDCARD_USER;

    function setUp() public override {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        evvm = new Evvm(
            ADMIN.Address,
            address(staking),
            EvvmStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );
        state = new State(address(evvm), ADMIN.Address);
        estimator = new Estimator(
            ACTIVATOR.Address,
            address(evvm),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(address(evvm), ADMIN.Address);

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));
        treasury = new Treasury(address(evvm));
        evvm.initializeSystemContracts(
            address(nameService),
            address(treasury),
            address(state)
        );

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        executeBeforeSetUp();
    }

    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    /**
     * Function to test:
     * nAdm: No admin execute the function
     * nNewAdm: No new admin execute the function
     * notInTime: Not in time to execute the function
     *
     */

    function test__unit_revert__constructor__AddressCantBeZero() external {
        uint256 sizeOfOpcode;
        address addressEvvmMock;
        vm.expectRevert(EvvmError.AddressCantBeZero.selector);
        evvmMock = new Evvm(
            address(0),
            address(staking),
            EvvmStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        addressEvvmMock = address(evvmMock);

        assembly {
            /// @dev check the size of the opcode of the address
            sizeOfOpcode := extcodesize(addressEvvmMock)
        }

        assertEq(
            sizeOfOpcode,
            0,
            "Evvm should not be deployed with zero address as admin"
        );

        vm.expectRevert(EvvmError.AddressCantBeZero.selector);
        evvmMock = new Evvm(
            ADMIN.Address,
            address(0),
            EvvmStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        addressEvvmMock = address(evvmMock);

        assembly {
            /// @dev check the size of the opcode of the address
            sizeOfOpcode := extcodesize(addressEvvmMock)
        }

        assertEq(
            sizeOfOpcode,
            0,
            "Evvm should not be deployed with zero address as staking contract"
        );
    }

    function test__unit_revert__setEvvmID__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.setEvvmID(1);
        vm.stopPrank();
    }

    function test__unit_revert__setEvvmID__WindowExpired() external {
        vm.startPrank(ADMIN.Address);
        evvm.setEvvmID(1);
        skip(26 hours);
        vm.expectRevert(EvvmError.WindowExpired.selector);
        evvm.setEvvmID(67);
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__IncorrectAddressInput() external {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(EvvmError.IncorrectAddressInput.selector);
        evvm.proposeAdmin(address(0));
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(EvvmError.IncorrectAddressInput.selector);
        evvm.proposeAdmin(ADMIN.Address);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposalAdmin__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.rejectProposalAdmin();

        vm.stopPrank();
    }

    function test__unit_revert__acceptAdmin__TimeLockNotExpired() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(EvvmError.TimeLockNotExpired.selector);
        evvm.acceptAdmin();

        vm.stopPrank();
    }

    function test__unit_revert__acceptAdmin__SenderIsNotTheProposedAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        skip(200 days);

        vm.expectRevert(EvvmError.SenderIsNotTheProposedAdmin.selector);
        evvm.acceptAdmin();

        vm.stopPrank();
    }
}

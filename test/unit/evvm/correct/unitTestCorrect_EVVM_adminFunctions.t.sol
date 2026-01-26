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

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";

contract unitTestCorrect_EVVM_adminFunctions is Test, Constants {
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
        estimator = new Estimator(
            ACTIVATOR.Address,
            address(evvm),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(address(evvm), ADMIN.Address);

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));
        treasury = new Treasury(address(evvm));
        evvm._setupNameServiceAndTreasuryAddress(
            address(nameService),
            address(treasury)
        );

        //evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        executeBeforeSetUp();
    }

    function test__unit_correct__proposeAdmin() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        assertEq(
            evvm.getCurrentAdmin(),
            ADMIN.Address,
            "Admin should be proposed not changed yet"
        );
    }

    function test__unit_correct__acceptAdmin() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1 hours);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        evvm.acceptAdmin();

        vm.stopPrank();

        assertEq(
            evvm.getCurrentAdmin(),
            COMMON_USER_NO_STAKER_1.Address,
            "Admin should be changed"
        );
    }

    function test__unit_correct__rejectProposalAdmin() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.warp(block.timestamp + 10 hours);

        evvm.rejectProposalAdmin();

        vm.stopPrank();

        assertEq(
            evvm.getCurrentAdmin(),
            ADMIN.Address,
            "Admin should be same because proposal was rejected"
        );
    }

    function test__unit_correct__setEvvmID() external {
        vm.startPrank(ADMIN.Address);

        evvm.setEvvmID(888);

        assertEq(evvm.getEvvmID(), 888);

        skip(20 hours);

        evvm.setEvvmID(777);

        vm.stopPrank();

        assertEq(evvm.getEvvmID(), 777, "EvvmID should be changed");
    }
}

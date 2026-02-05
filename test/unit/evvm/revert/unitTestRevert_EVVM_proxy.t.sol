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
contract unitTestRevert_EVVM_proxy is Test, Constants {
    /**
     * Naming Convention for Init Test Functions
     * Basic Structure:
     * test__init__[typeOfTest]__[functionName]__[options]
     * General Rules:
     *  - Always start with "test__"
     *  - The name of the function to be executed must immediately follow "test__"
     *  - Options are added at the end, separated by underscores
     *
     * Example:
     * test__init__pay_noStaker_sync__PF_nEX
     *
     * Example explanation:
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nEX: Does not include executor execution
     *
     * Notes:
     * Separate different parts of the name with double underscores (__)
     *
     * For this unit test two users execute 2 pay transactions before and
     * after the update, so insetad of the name of the function proxy we
     * going to use TxAndUseProxy to make the test more readable and
     * understandable
     *
     * Options fot this test:
     * - xU: Evvm updates x number of times
     */

    TartarusV1 v1;
    address addressV1;

    TartarusV2 v2;
    address addressV2;

    TartarusV3 v3;
    address addressV3;

    CounterDummy counter;
    address addressCounter;

    function executeBeforeSetUp() internal override {
        v1 = new TartarusV1();
        addressV1 = address(v1);

        v2 = new TartarusV2();
        addressV2 = address(v2);

        counter = new CounterDummy();
        addressCounter = address(counter);
        v3 = new TartarusV3(address(addressCounter));
        addressV3 = address(v3);
    }

    function test__unit_revert__fallback__ImplementationIsNotActive() external {
        vm.expectRevert(EvvmError.ImplementationIsNotActive.selector);

        ITartarusV1(address(evvm)).burnToken(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            10
        );
    }

    function test__unit_revert__proposeImplementation__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.proposeImplementation(addressV1);
        vm.stopPrank();
    }

    function test__unit_revert__proposeImplementation__IncorrectAddressInput()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(EvvmError.IncorrectAddressInput.selector);
        evvm.proposeImplementation(address(0));
        vm.stopPrank();
    }

    function test__unit_revert__rejectUpgrade__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(addressV1);
        vm.stopPrank();
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.rejectUpgrade();
        vm.stopPrank();
    }

    function test__unit_revert__acceptImplementation__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(addressV1);
        vm.stopPrank();
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(EvvmError.SenderIsNotAdmin.selector);
        evvm.acceptImplementation();
        vm.stopPrank();
    }

    function test__unit_revert__acceptImplementation__TimeLockNotExpired()
        external
    {
        vm.startPrank(ADMIN.Address);
        evvm.proposeImplementation(addressV1);

        vm.expectRevert(EvvmError.TimeLockNotExpired.selector);
        evvm.acceptImplementation();
        vm.stopPrank();
    }
}

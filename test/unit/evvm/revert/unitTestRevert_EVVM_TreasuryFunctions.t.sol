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
contract unitTestRevert_EVVM_TreasuryFunctions is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    //function executeBeforeSetUp() internal override {}

    function test__unit_revert__addAmountToUser__SenderIsNotTreasury() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(EvvmError.SenderIsNotTreasury.selector);
        evvm.addAmountToUser(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            100000000000 ether
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 because is not the Treasury.sol"
        );
    }

    function test__unit_revert__removeAmountFromUser__SenderIsNotTreasury() external {
        evvm.addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, 10 ether);
        
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(EvvmError.SenderIsNotTreasury.selector);
        evvm.addAmountToUser(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            10 ether
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            10 ether,
            "Sender balance must be 10 ether because is not the Treasury.sol"
        );
    }


}

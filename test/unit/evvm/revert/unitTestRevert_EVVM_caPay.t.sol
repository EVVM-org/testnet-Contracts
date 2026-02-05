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
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestRevert_EVVM_caPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        evvm.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    function test__unit_revert__caPay__NotAnCA() external {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, 0.1 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(EvvmError.NotAnCA.selector);
        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, 0.001 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.1 ether,
            "Amount should not be deducted because of revert"
        );
    }

    function test__unit_revert__caPay__InsufficientBalance() external {
        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, 0.1 ether);

        assertEq(
            evvm.getBalance(address(this), ETHER_ADDRESS),
            0 ether,
            "Amount should be 0 because of revert"
        );
    }
}

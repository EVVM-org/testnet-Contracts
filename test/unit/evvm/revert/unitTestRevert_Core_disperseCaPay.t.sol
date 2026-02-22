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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_Core_disperseCaPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        core.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    function test__unit_revert__disperseCaPay__NotAnCA() external {
        (uint256 amount) = _addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether
        );

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.NotAnCA.selector);
        core.disperseCaPay(toData, ETHER_ADDRESS, amount);
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount,
            "Amount should not be deducted because of revert"
        );
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Recipient balance should not change because of revert"
        );
    }

    function test__unit_revert__disperseCaPay__InsufficientBalance() external {
        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount * 2,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        vm.expectRevert(CoreError.InsufficientBalance.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        core.disperseCaPay(toData, ETHER_ADDRESS, amount * 2);

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            amount,
            "Amount should not be deducted because of revert"
        );
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Recipient balance should not change because of revert"
        );
    }

    function test__unit_revert__disperseCaPay__InvalidAmount() external {
        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](2);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount / 5,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = CoreStructs.DisperseCaPayMetadata({
            amount: amount / 5,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        vm.expectRevert(CoreError.InvalidAmount.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        core.disperseCaPay(toData, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            amount,
            "Amount should not be deducted because of revert"
        );
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Recipient balance should not change because of revert"
        );
    }

    function test__unit_revert__disperseCaPay__TokenIsDeniedForExecution_denyList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x02); // Activate denyList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        core.setTokenStatusOnDenyList(address(67), true);
        vm.stopPrank();

        _addBalance(address(this), address(67), 100);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](2);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: 50,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = CoreStructs.DisperseCaPayMetadata({
            amount: 50,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        vm.expectRevert(CoreError.TokenIsDeniedForExecution.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        core.disperseCaPay(toData, address(67), 100);
    }

    function test__unit_revert__disperseCaPay__TokenIsDeniedForExecution_allowList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01); // Activate allowList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        vm.stopPrank();

        _addBalance(address(this), address(67), 100);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](2);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: 50,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = CoreStructs.DisperseCaPayMetadata({
            amount: 50,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        vm.expectRevert(CoreError.TokenIsDeniedForExecution.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        core.disperseCaPay(toData, address(67), 100);
    }
}

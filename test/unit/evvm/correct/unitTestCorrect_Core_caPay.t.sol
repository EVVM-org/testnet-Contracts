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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {
    CoreError
} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestCorrect_Core_caPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        core.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    ///@dev because this script behaves like a smart contract we can use caPay
    ///     and disperseCaPay without any problem

    function test__unit_correct__caPay__noStaker() external {
        uint256 amount = _addBalance(address(this), ETHER_ADDRESS, 0.001 ether);

        core.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ca dont recieve rewards because is not an staker"
        );
    }

    function test__unit_correct__caPay__staker() external {
        uint256 amount = _addBalance(address(this), ETHER_ADDRESS, 0.001 ether);
        core.setPointStaker(address(this), 0x01);

        core.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount(),
            "ca recieve rewards because is an staker"
        );
    }
}

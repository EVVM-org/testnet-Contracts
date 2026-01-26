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

contract unitTestCorrect_EVVM_caPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        evvm.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    ///@dev because this script behaves like a smart contract we can use caPay
    ///     and disperseCaPay without any problem

    function test__unit_correct__caPay__noStaker() external {
        uint256 amount = _addBalance(address(this), ETHER_ADDRESS, 0.001 ether);

        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, amount);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            evvm.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            evvm.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ca dont recieve rewards because is not an staker"
        );
    }

    function test__unit_correct__caPay__staker() external {
        uint256 amount = _addBalance(address(this), ETHER_ADDRESS, 0.001 ether);
        evvm.setPointStaker(address(this), 0x01);

        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, amount);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            evvm.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            evvm.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount(),
            "ca recieve rewards because is an staker"
        );
    }
}

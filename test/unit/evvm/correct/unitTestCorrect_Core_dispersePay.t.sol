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
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestCorrect_Core_dispersePay is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;
    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            444,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            )
        );
    }

    function _addBalance(
        AccountData memory _user,
        address _token,
        uint256 _amount,
        uint256 _priorityFee
    ) private returns (uint256 amount, uint256 priorityFee) {
        core.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    function test__unit_correct__dispersePay__noSatker_sync() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.DispersePayMetadata[]
            memory toData = new CoreStructs.DispersePayMetadata[](2);

        toData[0] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _executeSig_evvm_dispersePay(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
                0,
                false
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);
        core.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            signature
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee,
            "Sender balance must be equal to priority fee because fisher is not staker"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_3.Address, ETHER_ADDRESS),
            0,
            "Fisher balance must be 0 because fisher is not staker"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Fisher balance must be 0 because fisher is not staker they cannot receive rewards"
        );
    }

    function test__unit_correct__dispersePay__noSatker_async() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.DispersePayMetadata[]
            memory toData = new CoreStructs.DispersePayMetadata[](2);

        toData[0] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _executeSig_evvm_dispersePay(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            67,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);
        core.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            67,
            true,
            signature
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee,
            "Sender balance must be equal to priority fee because fisher is not staker"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_3.Address, ETHER_ADDRESS),
            0,
            "Fisher balance must be 0 because fisher is not staker"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Fisher balance must be 0 because fisher is not staker they cannot receive rewards"
        );
    }

    function test__unit_correct__dispersePay__staker_sync() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.DispersePayMetadata[]
            memory toData = new CoreStructs.DispersePayMetadata[](2);

        toData[0] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _executeSig_evvm_dispersePay(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
                0,
                false
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            signature
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 becasue all the amount and priority fee were distributed"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee,
            "Fisher must receive the priority fee because fisher is staker"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Fisher balance must be rewarded because fisher is staker"
        );
    }

    function test__unit_correct__dispersePay__staker_async() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.DispersePayMetadata[]
            memory toData = new CoreStructs.DispersePayMetadata[](2);

        toData[0] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = CoreStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _executeSig_evvm_dispersePay(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            67,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            67,
            true,
            signature
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 becasue all the amount and priority fee were distributed"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee,
            "Fisher must receive the priority fee because fisher is staker"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Fisher balance must be rewarded because fisher is staker"
        );
    }
}

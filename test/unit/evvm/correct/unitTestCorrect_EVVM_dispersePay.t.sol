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
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestCorrect_EVVM_dispersePay is Test, Constants, EvvmStructs {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;
    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
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
        evvm.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    function test__unit_correct__dispersePay__noSatker_sync() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee,
            "Sender balance must be equal to priority fee because fisher is not staker"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_3.Address, ETHER_ADDRESS),
            0,
            "Fisher balance must be 0 because fisher is not staker"
        );

        assertEq(
            evvm.getBalance(
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

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            67,
            true,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            67,
            true,
            address(0),
            signature
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee,
            "Sender balance must be equal to priority fee because fisher is not staker"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_3.Address, ETHER_ADDRESS),
            0,
            "Fisher balance must be 0 because fisher is not staker"
        );

        assertEq(
            evvm.getBalance(
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

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 becasue all the amount and priority fee were distributed"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee,
            "Fisher must receive the priority fee because fisher is staker"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
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

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            67,
            true,
            address(0)
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            67,
            true,
            address(0),
            signature
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 becasue all the amount and priority fee were distributed"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Receiver balance must be equal to all amount sent"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee,
            "Fisher must receive the priority fee because fisher is staker"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
            "Fisher balance must be rewarded because fisher is staker"
        );
    }
}

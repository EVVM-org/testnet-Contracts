// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */
pragma solidity ^0.8.0;
pragma abicoder v2;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract fuzzTest_EVVM_pay is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x00);
    }

    function _makeRandomUsername(
        uint16 seed
    ) private returns (string memory username) {
        // Generate a length between 4 and 12 characters (inclusive)
        uint256 minLen = 4;
        uint256 maxExtra = 8; // allows lengths from 4 to 12
        uint256 len = minLen + (uint256(seed) % (maxExtra + 1));

        bytes memory usernameBytes = new bytes(len);

        // Ensure first character is a letter (A-Z or a-z)
        uint256 r0 = uint256(keccak256(abi.encodePacked(seed, "first"))) % 52;
        usernameBytes[0] = r0 < 26
            ? bytes1(uint8(r0 + 65))
            : bytes1(uint8(r0 + 71));

        // Fill remaining characters with digits (0-9), uppercase (A-Z) or lowercase (a-z)
        for (uint256 i = 1; i < len; i++) {
            uint256 r = uint256(keccak256(abi.encodePacked(seed, i))) % 62;
            if (r < 10) {
                usernameBytes[i] = bytes1(uint8(48 + r)); // '0'..'9'
            } else if (r < 36) {
                usernameBytes[i] = bytes1(uint8(65 + (r - 10))); // 'A'..'Z'
            } else {
                usernameBytes[i] = bytes1(uint8(97 + (r - 36))); // 'a'..'z'
            }
        }

        username = string(usernameBytes);

        // Register the username for the test user
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_2,
            username,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
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

    struct PayInputsToAddress {
        bool usingExecutor;
        bool isUsingAsyncNonce;
        bool isExecutorStaker;
        address toAddress;
        address token;
        uint16 amount;
        uint16 priorityFee;
        address executor;
        uint136 asyncNonce;
    }

    function test__fuzz__pay__toAddress(
        PayInputsToAddress memory input
    ) external {
        vm.assume(
            input.amount > 0 &&
                input.token != PRINCIPAL_TOKEN_ADDRESS &&
                input.executor != input.toAddress &&
                input.executor != COMMON_USER_NO_STAKER_1.Address &&
                input.toAddress != COMMON_USER_NO_STAKER_1.Address &&
                input.executor != address(staking)
        );

        uint256 nonce = input.isUsingAsyncNonce
            ? input.asyncNonce
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            input.token,
            input.amount,
            input.priorityFee
        );

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            input.toAddress,
            "",
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce
        );

        evvm.setPointStaker(
            input.executor,
            input.isExecutorStaker ? bytes1(0x01) : bytes1(0x00)
        );
        vm.startPrank(input.executor);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            input.toAddress,
            "",
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.isExecutorStaker ? 0 : priorityFee,
            "Sender balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(input.toAddress, input.token),
            amount,
            "Balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(input.executor, input.token),
            input.isExecutorStaker ? uint256(priorityFee) : 0,
            "Executor balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(input.executor, PRINCIPAL_TOKEN_ADDRESS),
            input.isExecutorStaker ? evvm.getRewardAmount() : 0,
            "Executor balance after check if executor should not or should recieve rewards incorrect"
        );
    }

    struct PayInputsToIdentity {
        bool usingExecutor;
        bool isUsingAsyncNonce;
        bool isExecutorStaker;
        address token;
        uint16 amount;
        uint16 priorityFee;
        address executor;
        uint136 asyncNonce;
        uint16 seedUsername;
    }

    function test__fuzz__pay__toIdentity(
        PayInputsToIdentity memory input
    ) external {
        vm.assume(
            input.amount > 0 &&
                input.token != PRINCIPAL_TOKEN_ADDRESS &&
                input.executor != COMMON_USER_NO_STAKER_1.Address &&
                input.executor != COMMON_USER_NO_STAKER_2.Address &&
                input.executor != address(staking)
        );

        uint256 nonce = input.isUsingAsyncNonce
            ? input.asyncNonce
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            input.token,
            input.amount,
            input.priorityFee
        );

        string memory username = _makeRandomUsername(input.seedUsername);

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            username,
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce
        );

        evvm.setPointStaker(
            input.executor,
            input.isExecutorStaker ? bytes1(0x01) : bytes1(0x00)
        );
        vm.startPrank(input.executor);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            username,
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.isExecutorStaker ? 0 : priorityFee,
            "Sender balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            amount,
            "Balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(input.executor, input.token),
            input.isExecutorStaker ? uint256(priorityFee) : 0,
            "Executor balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(input.executor, PRINCIPAL_TOKEN_ADDRESS),
            input.isExecutorStaker ? evvm.getRewardAmount() : 0,
            "Executor balance after check if executor should not or should recieve rewards incorrect"
        );
    }
}

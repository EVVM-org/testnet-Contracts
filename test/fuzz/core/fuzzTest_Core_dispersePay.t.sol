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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract fuzzTest_Core_dispersePay is Test, Constants {
    function executeBeforeSetUp() internal override {
        core.setPointStaker(COMMON_USER_STAKER.Address, 0x00);
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
            444,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            address(0),
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
        core.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    struct PayInputs {
        bool usingExecutor;
        bool isUsingAsyncNonce;
        bool isExecutorStaker;
        address toAddressA;
        address token;
        uint16 amountA;
        uint16 amountB;
        uint16 priorityFee;
        address executor;
        uint136 asyncNonce;
        uint16 seedUsername;
    }

    function test__fuzz__dispersePay(PayInputs memory input) external {
        vm.assume(
            input.amountA > 0 &&
                input.amountB > 0 &&
                input.token != PRINCIPAL_TOKEN_ADDRESS &&
                input.executor != input.toAddressA &&
                input.executor != COMMON_USER_NO_STAKER_2.Address &&
                input.executor != COMMON_USER_NO_STAKER_1.Address &&
                input.toAddressA != COMMON_USER_NO_STAKER_1.Address &&
                input.toAddressA != COMMON_USER_NO_STAKER_2.Address
        );

        string memory username = _makeRandomUsername(input.seedUsername);

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            input.token,
            uint256(input.amountA) + uint256(input.amountB),
            input.priorityFee
        );

        CoreStructs.DispersePayMetadata[]
            memory toData = new CoreStructs.DispersePayMetadata[](2);

        toData[0] = CoreStructs.DispersePayMetadata({
            amount: input.amountA,
            to_address: input.toAddressA,
            to_identity: ""
        });

        toData[1] = CoreStructs.DispersePayMetadata({
            amount: input.amountB,
            to_address: address(0),
            to_identity: username
        });

        uint256 nonce = input.isUsingAsyncNonce
            ? input.asyncNonce
            : core.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        bytes memory signaturePay = _executeSig_evvm_dispersePay(
            COMMON_USER_NO_STAKER_1,
            toData,
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce
        );

        core.setPointStaker(
            input.executor,
            input.isExecutorStaker ? bytes1(0x01) : bytes1(0x00)
        );
        vm.startPrank(input.executor);
        core.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            input.token,
            amount,
            priorityFee,
            input.usingExecutor ? input.executor : address(0),
            nonce,
            input.isUsingAsyncNonce,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.isExecutorStaker ? 0 : priorityFee,
            "Sender balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(input.toAddressA, input.token),
            input.amountA,
            "Balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            input.amountB,
            "Balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(input.executor, input.token),
            input.isExecutorStaker ? uint256(priorityFee) : 0,
            "Executor balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(input.executor, PRINCIPAL_TOKEN_ADDRESS),
            input.isExecutorStaker ? core.getRewardAmount() : 0,
            "Executor balance after check if executor should not or should recieve rewards incorrect"
        );
    }
}

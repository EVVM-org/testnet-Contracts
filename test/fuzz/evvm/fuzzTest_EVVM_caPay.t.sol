// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM functions
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

contract fuzzTest_EVVM_caPay is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    struct caPayFuzzTestInput {
        bytes32 salt;
        uint32 amount;
        address token;
        bool isCaStaker;
    }

    function test__fuzz__caPay(caPayFuzzTestInput memory input) external {
        vm.assume(input.amount > 0);
        HelperCa c = new HelperCa{salt: input.salt}(address(evvm));
        if (input.isCaStaker) {
            evvm.setPointStaker(address(c), 0x01);
        }

        addBalance(address(c), input.token, input.amount);

        c.makeCaPay(COMMON_USER_NO_STAKER_1.Address, input.token, input.amount);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.amount
        );

        assertEq(
            evvm.getBalance(address(c), PRINCIPAL_TOKEN_ADDRESS),
            input.isCaStaker ? evvm.getRewardAmount() : 0
        );
    }
}

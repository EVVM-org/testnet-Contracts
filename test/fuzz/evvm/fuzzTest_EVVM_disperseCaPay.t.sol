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

import {Constants, HelperCa} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_EVVM_disperseCaPay is Test, Constants {
    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    struct caPayFuzzTestInput {
        bytes32 salt;
        uint32 amountA;
        uint32 amountB;
        address token;
        bool isCaStaker;
    }

    function test__fuzz__disperseCaPay(
        caPayFuzzTestInput memory input
    ) external {
        vm.assume(input.amountA > 0 && input.amountB > 0);
        HelperCa c = new HelperCa{salt: input.salt}(address(evvm));
        if (input.isCaStaker) {
            evvm.setPointStaker(address(c), 0x01);
        }

        uint256 amountTotal = uint256(input.amountA) + uint256(input.amountB);

        addBalance(address(c), input.token, amountTotal);

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata({
            amount: input.amountA,
            toAddress: COMMON_USER_NO_STAKER_1.Address
        });

        toData[1] = EvvmStructs.DisperseCaPayMetadata({
            amount: input.amountB,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        c.makeDisperseCaPay(toData, input.token, amountTotal);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.amountA
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            input.amountB
        );

        assertEq(
            evvm.getBalance(address(c), PRINCIPAL_TOKEN_ADDRESS),
            input.isCaStaker ? evvm.getRewardAmount() : 0
        );
    }
}

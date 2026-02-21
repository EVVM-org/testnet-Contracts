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

contract fuzzTest_Core_caPay is Test, Constants {
    function executeBeforeSetUp() internal override {
        
    }

    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }

    struct caPayFuzzTestInput {
        bytes32 salt;
        uint32 amount;
        address token;
        bool isCaStaker;
    }

    function test__fuzz__caPay(caPayFuzzTestInput memory input) external {
        vm.assume(input.amount > 0);
        HelperCa c = new HelperCa{salt: input.salt}(address(core));
        if (input.isCaStaker) {
            core.setPointStaker(address(c), 0x01);
        }

        addBalance(address(c), input.token, input.amount);

        c.makeCaPay(COMMON_USER_NO_STAKER_1.Address, input.token, input.amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            input.amount
        );

        assertEq(
            core.getBalance(address(c), PRINCIPAL_TOKEN_ADDRESS),
            input.isCaStaker ? core.getRewardAmount() : 0
        );
    }
}

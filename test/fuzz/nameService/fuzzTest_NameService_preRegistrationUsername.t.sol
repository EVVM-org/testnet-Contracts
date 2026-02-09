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
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

contract fuzzTest_NameService_preRegistrationUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    struct Params {
        AccountData user;
        string username;
        uint256 lockNumber;
        uint256 nonce;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool isAsyncExecEvvm;
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFee
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFee);

        return priorityFee;
    }

    struct Input {
        string username;
        uint256 lockNumber;
        uint256 nonce;
        uint32 priorityFee;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEvvm;
    }

    function test__fuzz__preRegistrationUsername__noStaker(
        Input memory input
    ) external {
        vm.assume(input.nonce != input.nonceAsyncEVVM);
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: input.username,
            lockNumber: input.lockNumber,
            nonce: input.nonce,
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm
        });

        _addBalance(params.user, params.priorityFee);

        (
            bytes memory signatureNameServiceOne,
            bytes memory signatureEvvmOne
        ) = _executeSig_nameService_preRegistrationUsername(
                params.user,
                params.username,
                params.lockNumber,
                params.nonce,
                params.priorityFee,
                params.nonceEVVM,
                params.isAsyncExecEvvm
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            params.user.Address,
            keccak256(
                abi.encodePacked(params.username, uint256(params.lockNumber))
            ),
            params.nonce,
            signatureNameServiceOne,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            signatureEvvmOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params.username,
                            uint256(params.lockNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Error NonStaker: username not preregistered correctly"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
    }

    function test__fuzz__preRegistrationUsername__staker(
        Input memory input
    ) external {
        vm.assume(input.nonce != input.nonceAsyncEVVM);
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: input.username,
            lockNumber: input.lockNumber,
            nonce: input.nonce,
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm
        });

        _addBalance(params.user, params.priorityFee);

        (
            bytes memory signatureNameServiceOne,
            bytes memory signatureEvvmOne
        ) = _executeSig_nameService_preRegistrationUsername(
                params.user,
                params.username,
                params.lockNumber,
                params.nonce,
                params.priorityFee,
                params.nonceEVVM,
                params.isAsyncExecEvvm
            );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.preRegistrationUsername(
            params.user.Address,
            keccak256(
                abi.encodePacked(params.username, uint256(params.lockNumber))
            ),
            params.nonce,
            signatureNameServiceOne,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            signatureEvvmOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params.username,
                            uint256(params.lockNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Error NonStaker: username not preregistered correctly"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + params.priorityFee,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }
}

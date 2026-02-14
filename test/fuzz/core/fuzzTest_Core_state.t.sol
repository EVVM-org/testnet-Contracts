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

contract fuzzTest_Core_state is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    struct InputsValidateAndConsumeNonce {
        string testA;
        uint256 testB;
        address testC;
        bool testD;
        uint256 nonceAsync;
        bool isAsyncExec;
        bool callFromEOA;
    }

    function test__fuzz__validateAndConsumeNonce(
        InputsValidateAndConsumeNonce memory inputs
    ) external {
        bytes memory signature = _executeSig_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            inputs.testA,
            inputs.testB,
            inputs.testC,
            inputs.testD,
            address(0),
            inputs.isAsyncExec
                ? inputs.nonceAsync
                : core.getNextCurrentSyncNonce(
                    COMMON_USER_NO_STAKER_1.Address
                ),
            inputs.isAsyncExec
        );

        core.validateAndConsumeNonce(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(
                abi.encode(
                    "StateTest",
                    inputs.testA,
                    inputs.testB,
                    inputs.testC,
                    inputs.testD
                )
            ),
            address(0),
            inputs.isAsyncExec
                ? inputs.nonceAsync
                : core.getNextCurrentSyncNonce(
                    COMMON_USER_NO_STAKER_1.Address
                ),
            inputs.isAsyncExec,
            signature
        );

        if (inputs.isAsyncExec) {
            assertTrue(
                core.getIfUsedAsyncNonce(
                    COMMON_USER_NO_STAKER_1.Address,
                    inputs.nonceAsync
                ),
                "Async nonce should be marked as used after consumption"
            );
        } else {
            assertEq(
                core.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                1,
                "Sync nonce should be incremented after successful consumption"
            );
        }
    }

    struct InputsReserveAsyncNonce {
        address user;
        uint256 nonceAsync;
        address serviceAddress;
    }

    function test__fuzz__reserveAsyncNonce(
        InputsReserveAsyncNonce memory inputs
    ) external {
        vm.assume(inputs.user != address(0));
        vm.assume(inputs.serviceAddress != address(0));

        vm.startPrank(inputs.user);
        core.reserveAsyncNonce(inputs.nonceAsync, inputs.serviceAddress);
        vm.stopPrank();

        assertEq(
            core.getAsyncNonceReservation(inputs.user, inputs.nonceAsync),
            inputs.serviceAddress,
            "Async nonce reservation should store the correct service address"
        );
        assertEq(
            uint256(
                uint8(core.asyncNonceStatus(inputs.user, inputs.nonceAsync))
            ),
            uint256(0x02),
            "Async nonce status should be 0x02 (reserved) after reservation"
        );
    }

    function test__unit_correct__revokeAsyncNonce(
        InputsReserveAsyncNonce memory inputs
    ) external {
        vm.assume(inputs.user != address(0));
        vm.assume(inputs.serviceAddress != address(0));

        vm.startPrank(inputs.user);
        core.reserveAsyncNonce(inputs.nonceAsync, inputs.serviceAddress);
        core.revokeAsyncNonce(inputs.user, inputs.nonceAsync);
        vm.stopPrank();

        assertEq(
            core.getAsyncNonceReservation(inputs.user, inputs.nonceAsync),
            address(0),
            "Async nonce reservation should be cleared after revocation"
        );

        assertEq(
            uint256(
                uint8(core.asyncNonceStatus(inputs.user, inputs.nonceAsync))
            ),
            uint256(0x00),
            "Async nonce status should be 0x00 (available) after revocation"
        );
    }
}

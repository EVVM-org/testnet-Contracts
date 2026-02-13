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

contract unitTestCorrect_State_functions is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    struct InputsValidateAndConsumeNonce {
        AccountData user;
        string testA;
        uint256 testB;
        address testC;
        bool testD;
    }

    function test__unit_correct__validateAndConsumeNonce_async() external {
        InputsValidateAndConsumeNonce
            memory inputs = InputsValidateAndConsumeNonce({
                user: COMMON_USER_NO_STAKER_1,
                testA: "textTest",
                testB: 123,
                testC: address(321),
                testD: false
            });
        bytes memory signature = _executeSig_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            inputs.testA,
            inputs.testB,
            inputs.testC,
            inputs.testD,
            67,
            true
        );

        state.validateAndConsumeNonce(
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
            67,
            true,
            signature
        );

        assertTrue(
            state.getIfUsedAsyncNonce(COMMON_USER_NO_STAKER_1.Address, 67),
            "Async nonce should be marked as used after consumption"
        );
    }

    function test__unit_correct__validateAndConsumeNonce_sync() external {
        InputsValidateAndConsumeNonce
            memory inputs = InputsValidateAndConsumeNonce({
                user: COMMON_USER_NO_STAKER_1,
                testA: "textTest",
                testB: 123,
                testC: address(321),
                testD: false
            });
        bytes memory signature = _executeSig_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            inputs.testA,
            inputs.testB,
            inputs.testC,
            inputs.testD,
            state.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false
        );

        state.validateAndConsumeNonce(
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
            state.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signature
        );

        assertEq(
            state.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            1,
            "Sync nonce should be incremented after successful consumption"
        );
    }

    function test__unit_correct__reserveAsyncNonce() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        state.reserveAsyncNonce(45, address(this));
        vm.stopPrank();

        assertEq(
            state.getAsyncNonceReservation(COMMON_USER_NO_STAKER_1.Address, 45),
            address(this),
            "Async nonce reservation should store the correct service address"
        );
        assertEq(
            uint256(
                uint8(
                    state.asyncNonceStatus(COMMON_USER_NO_STAKER_1.Address, 45)
                )
            ),
            uint256(0x02),
            "Async nonce status should be 0x02 (reserved) after reservation"
        );
    }

    function test__unit_correct__revokeAsyncNonce() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        state.reserveAsyncNonce(45, address(this));
        state.revokeAsyncNonce(COMMON_USER_NO_STAKER_1.Address, 45);
        vm.stopPrank();

        assertEq(
            state.getAsyncNonceReservation(COMMON_USER_NO_STAKER_1.Address, 45),
            address(0),
            "Async nonce reservation should be cleared after revocation"
        );

        assertEq(
            uint256(
                uint8(
                    state.asyncNonceStatus(COMMON_USER_NO_STAKER_1.Address, 45)
                )
            ),
            uint256(0x00),
            "Async nonce status should be 0x00 (available) after revocation"
        );
    }
}

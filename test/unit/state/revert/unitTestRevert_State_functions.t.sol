// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   ___/ __ \ /  ___\   __\
|    |  |   |  |  ||  |    |  | \  ___/ \___ \ |  |  
|______/|___|  |__||__|    |__|  \___  /____  >|__|  
             \/                      \/     \/       
                                  __                 
_______  _______  __ ____________/  |_               
\_  __ _/ __ \  \/ _/ __ \_  __ \   __\              
 |  | \\  ___/\   /\  ___/|  | \/|  |                
 |__|   \___  >\_/  \___  |__|   |__|                
            \/          \/                                                                                 
 */

pragma solidity ^0.8.0;
pragma abicoder v2;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/errors/StateError.sol";

contract unitTestRevert_State_functions is Test, Constants {
    UserValidator private userValidatorMock;
    function executeBeforeSetUp() internal override {
        userValidatorMock = new UserValidator();
    }

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

    function test__unit_revert__validateAndConsumeNonce__MsgSenderIsNotAContract()
        external
    {
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

        /* 🢃 non CA tries to interact 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StateError.MsgSenderIsNotAContract.selector);
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
        vm.stopPrank();
    }

    function test__unit_revert__validateAndConsumeNonce__InvalidSignature()
        external
    {
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

        vm.expectRevert(StateError.InvalidSignature.selector);
        state.validateAndConsumeNonce(
            COMMON_USER_NO_STAKER_1.Address,
            /* 🢃 diferent input compared to signature 🢃 */
            keccak256(
                abi.encode(
                    "StateTest",
                    "diferentText",
                    inputs.testB + 1,
                    inputs.testC,
                    inputs.testD
                )
            ),
            67,
            true,
            signature
        );
    }

    function test__unit_revert__validateAndConsumeNonce__UserCannotExecuteTransaction()
        external
    {
        vm.startPrank(ADMIN.Address);
        state.proposeUserValidator(address(userValidatorMock));
        skip(1 days);
        state.acceptUserValidatorProposal();
        vm.stopPrank();

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

        vm.expectRevert(StateError.UserCannotExecuteTransaction.selector);
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
    }

    function test__unit_revert__validateAndConsumeNonce__AsyncNonceAlreadyUsed()
        external
    {
        InputsValidateAndConsumeNonce
            memory inputs = InputsValidateAndConsumeNonce({
                user: COMMON_USER_NO_STAKER_1,
                testA: "textTest",
                testB: 123,
                testC: address(321),
                testD: false
            });

        _executeFn_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            "textTest",
            123,
            address(321),
            false,
            67,
            true
        );
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

        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
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
    }

    function test__unit_revert__validateAndConsumeNonce__AsyncNonceIsReservedByAnotherService()
        external
    {
        InputsValidateAndConsumeNonce
            memory inputs = InputsValidateAndConsumeNonce({
                user: COMMON_USER_NO_STAKER_1,
                testA: "textTest",
                testB: 123,
                testC: address(321),
                testD: false
            });

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        state.reserveAsyncNonce(67, address(125));
        vm.stopPrank();

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

        vm.expectRevert(
            StateError.AsyncNonceIsReservedByAnotherService.selector
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
    }

    function test__unit_revert__validateAndConsumeNonce__SyncNonceMismatch()
        external
    {
        InputsValidateAndConsumeNonce
            memory inputs = InputsValidateAndConsumeNonce({
                user: COMMON_USER_NO_STAKER_1,
                testA: "textTest",
                testB: 123,
                testC: address(321),
                testD: false
            });
        uint256 currentSyncNonce = state.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        _executeFn_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            "textTest",
            123,
            address(321),
            false,
            currentSyncNonce,
            false
        );

        bytes memory signature = _executeSig_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            inputs.testA,
            inputs.testB,
            inputs.testC,
            inputs.testD,
            currentSyncNonce,
            false
        );

        vm.expectRevert(StateError.SyncNonceMismatch.selector);
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
            currentSyncNonce,
            false,
            signature
        );
    }

    function test__unit_revert__reserveAsyncNonce__InvalidServiceAddress()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(StateError.InvalidServiceAddress.selector);
        state.reserveAsyncNonce(67, address(0));
        vm.stopPrank();
    }

    function test__unit_revert__reserveAsyncNonce__AsyncNonceAlreadyUsed()
        external
    {
        _executeFn_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            "textTest",
            123,
            address(321),
            false,
            67,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
        state.reserveAsyncNonce(67, address(this));
        vm.stopPrank();
    }

    function test__unit_revert__reserveAsyncNonce__AsyncNonceAlreadyReserved()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        state.reserveAsyncNonce(67, address(125));
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(StateError.AsyncNonceAlreadyReserved.selector);
        state.reserveAsyncNonce(67, address(this));
        vm.stopPrank();
    }

    function test__unit_revert__revokeAsyncNonce__AsyncNonceAlreadyUsed()
        external
    {
        _executeFn_state_test(
            COMMON_USER_NO_STAKER_1,
            address(this),
            "textTest",
            123,
            address(321),
            false,
            67,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
        state.revokeAsyncNonce(COMMON_USER_NO_STAKER_1.Address, 67);
        vm.stopPrank();
    }

    function test__unit_revert__revokeAsyncNonce__AsyncNonceNotReserved()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(StateError.AsyncNonceNotReserved.selector);
        state.revokeAsyncNonce(COMMON_USER_NO_STAKER_1.Address, 67);
        vm.stopPrank();
    }
}

contract UserValidator {
    function canExecute(address user) external pure returns (bool) {
        return false;
    }
}

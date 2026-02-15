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

contract fuzzTest_NameService_registrationUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER = COMMON_USER_NO_STAKER_1;

    struct Params {
        AccountData user;
        string username;
        uint256 lockNumber;
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 noncePay;
        bytes signaturePay;
    }

    function _addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFee
    )
        private
        returns (uint256 registrationPrice, uint256 totalPriorityFeeAmount)
    {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username) + priorityFee
        );

        return (nameService.getPriceOfRegistration(username), priorityFee);
    }

    /// @dev Generates a valid username based on a seed and maximum length
    /// @param seed Seed for pseudo-random generation
    /// @param maxLength Maximum length of the string (minimum 4)
    /// @return A valid username that meets all rules
    function generateValidUsername(
        uint256 seed,
        uint256 maxLength
    ) internal pure returns (string memory) {
        // Ensure the length is at least 4
        if (maxLength < 4) maxLength = 4;

        // Generate a random length between 4 and maxLength
        uint256 length = 4 + (seed % (maxLength - 3));

        bytes memory username = new bytes(length);

        // First character: must be a letter (A-Z or a-z)
        // There are 52 letters in total (26 uppercase + 26 lowercase)
        uint256 randomValue = uint256(
            keccak256(abi.encodePacked(seed, uint256(0)))
        );
        uint256 letterIndex = randomValue % 52;

        if (letterIndex < 26) {
            // Uppercase letter (A-Z): 0x41 to 0x5A
            username[0] = bytes1(uint8(0x41 + letterIndex));
        } else {
            // Lowercase letter (a-z): 0x61 to 0x7A
            username[0] = bytes1(uint8(0x61 + (letterIndex - 26)));
        }

        // Remaining characters: can be letters or digits
        // Total: 62 options (26 uppercase + 26 lowercase + 10 digits)
        for (uint256 i = 1; i < length; i++) {
            randomValue = uint256(keccak256(abi.encodePacked(seed, i)));
            uint256 charIndex = randomValue % 62;

            if (charIndex < 10) {
                // Digit (0-9): 0x30 to 0x39
                username[i] = bytes1(uint8(0x30 + charIndex));
            } else if (charIndex < 36) {
                // Uppercase letter (A-Z): 0x41 to 0x5A
                username[i] = bytes1(uint8(0x41 + (charIndex - 10)));
            } else {
                // Lowercase letter (a-z): 0x61 to 0x7A
                username[i] = bytes1(uint8(0x61 + (charIndex - 36)));
            }
        }

        return string(username);
    }

    struct Input {
        uint8 secondsToSkip;
        uint32 seed;
        uint8 maxLength;
        uint256 lockNumber;
        uint256 nonce;
        uint32 priorityFee;
        uint256 nonceAsyncEVVM;
    }

    function test__fuzz__registrationUsername__noStaker(
        Input memory input
    ) external {
        vm.assume(input.nonce > 2);
        vm.assume(input.nonceAsyncEVVM > 2);
        vm.assume(input.nonce != input.nonceAsyncEVVM);

        string memory USERNAME = generateValidUsername(
            uint256(input.seed),
            uint256(input.maxLength)
        );
        _executeFn_nameService_preRegistrationUsername(
            USER,
            USERNAME,
            input.lockNumber,
            address(0),
            0
        );

        skip(30 minutes + (input.secondsToSkip * 1 seconds));

        Params memory params = Params({
            user: USER,
            username: USERNAME,
            lockNumber: input.lockNumber,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            noncePay: input.nonceAsyncEVVM,
            signaturePay: ""
        });
        _addBalance(params.user, params.username, params.priorityFee);
        (
            params.signatureNameService,
            params.signaturePay
        ) = _executeSig_nameService_registrationUsername(
            params.user,
            USERNAME,
            params.lockNumber,address(0),
            params.nonce,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params.user.Address,
            USERNAME,
            params.lockNumber,address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();

        (address ownerOne, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            ownerOne,
            params.user.Address,
            "Error no staker: username not registered correctly"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );
    }


    function test__fuzz__registrationUsername__staker(
        Input memory input
    ) external {
        vm.assume(input.nonce > 2);
        vm.assume(input.nonceAsyncEVVM > 2);
        vm.assume(input.nonce != input.nonceAsyncEVVM);
        string memory USERNAME = generateValidUsername(
            uint256(input.seed),
            uint256(input.maxLength)
        );
        _executeFn_nameService_preRegistrationUsername(
            USER,
            USERNAME,
            input.lockNumber,
            address(0),
            0
        );

        skip(30 minutes + (input.secondsToSkip * 1 seconds));

        Params memory params = Params({
            user: USER,
            username: USERNAME,
            lockNumber: input.lockNumber,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            noncePay: input.nonceAsyncEVVM,
            signaturePay: ""
        });
        _addBalance(params.user, params.username, params.priorityFee);
        (
            params.signatureNameService,
            params.signaturePay
        ) = _executeSig_nameService_registrationUsername(
            params.user,
            USERNAME,
            params.lockNumber,address(0),
            params.nonce,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params.user.Address,
            USERNAME,
            params.lockNumber,address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();

        (address ownerOne, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            ownerOne,
            params.user.Address,
            "Error no staker: username not registered correctly"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * core.getRewardAmount()) + params.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }
}

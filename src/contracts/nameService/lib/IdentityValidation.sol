// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title IdentityValidation - Validation Library
 * @author Mate labs
 * @notice Library for validating usernames and identities
 * @dev Pure validation at byte level (gas efficient). Username: 4+ chars, starts with letter, alphanumeric only. Email: prefix@domain.tld. Phone: numeric with length constraints.
 */
library IdentityValidation{
    /**
     * @notice Validates username format per system rules
     * @dev Username must be 4+ chars, start with letter,
     *      contain only letters/digits
     *
     * Validation Rules:
     * - Minimum length: 4 characters
     * - Must start with a letter (A-Z or a-z)
     * - Can only contain letters and digits
     * - No special characters or spaces allowed
     *
     * @param username The username string to validate
     * @return True if valid username format, false otherwise
     */
    function isValidUsername(string memory username) internal pure returns (bool) {
        bytes memory usernameBytes = bytes(username);

        // Check if username length is at least 4 characters
        if (usernameBytes.length < 4) return false;

        // Check if username begins with a letter
        if (!_isLetter(usernameBytes[0]))
            return false;


        // Iterate through each character in the username
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            // Check if character is not a digit or letter
            if (!_isDigit(usernameBytes[i]) && !_isLetter(usernameBytes[i])) {
                return false;

            }
        }
        return true;
    }

    /**
     * @notice Validates phone number format
     * @dev Phone number must be 6-19 digits only
     * @param _phoneNumber The phone number string to validate
     * @return True if valid phone number format
     */
    function isValidPhoneNumberNumber(
        string memory _phoneNumber
    ) internal pure returns (bool) {
        bytes memory _telephoneNumberBytes = bytes(_phoneNumber);
        if (
            _telephoneNumberBytes.length < 20 &&
            _telephoneNumberBytes.length > 5
        ) {
            return false;
        }
        for (uint256 i = 0; i < _telephoneNumberBytes.length; i++) {
            if (!_isDigit(_telephoneNumberBytes[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Validates email address format
     * @dev Checks for proper email structure: prefix(3+ chars) + @ + domain(3+ chars) + . + TLD(2+ chars)
     * @param _email The email address string to validate
     * @return True if valid email format
     */
    function isValidEmail(string memory _email) internal pure returns (bool) {
        bytes memory _emailBytes = bytes(_email);
        uint256 lengthCount = 0;
        bytes1 flagVerify = 0x00;
        for (uint point = 0; point < _emailBytes.length; point++) {
            //step 1 0x00 prefix
            if (flagVerify == 0x00) {
                if (_isOnlyEmailPrefixCharacters(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAAt(_emailBytes[point])) {
                        flagVerify = 0x01;
                    } else {
                        return false;
                    }
                }
            }

            //step 2 0x01 count the prefix length
            if (flagVerify == 0x01) {
                if (lengthCount < 3) {
                    return false;
                } else {
                    flagVerify = 0x02;
                    lengthCount = 0;
                    point++;
                }
            }

            //step 3 0x02 domain name
            if (flagVerify == 0x02) {
                if (_isLetter(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAPoint(_emailBytes[point])) {
                        flagVerify = 0x03;
                    } else {
                        return false;
                    }
                }
            }

            //step 4 0x03 count the domain name length
            if (flagVerify == 0x03) {
                if (lengthCount < 3) {
                    return false;
                } else {
                    flagVerify = 0x04;
                    lengthCount = 0;
                    point++;
                }
            }

            //step 5 0x04 top level domain
            if (flagVerify == 0x04) {
                if (_isLetter(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAPoint(_emailBytes[point])) {
                        if (lengthCount < 2) {
                            return false;
                        } else {
                            lengthCount = 0;
                        }
                    } else {
                        return false;
                    }
                }
            }
        }

        if (flagVerify != 0x04) {
            return false;
        }

        return true;
    }

    /// @dev Checks if a byte represents a digit (0-9)
    function _isDigit(bytes1 character) private pure returns (bool) {
        return (character >= 0x30 && character <= 0x39); // ASCII range for digits 0-9
    }

    /// @dev Checks if a byte represents a letter (A-Z or a-z)
    function _isLetter(bytes1 character) private pure returns (bool) {
        return ((character >= 0x41 && character <= 0x5A) ||
            (character >= 0x61 && character <= 0x7A)); // ASCII ranges for letters A-Z and a-z
    }

    /// @dev Checks if a byte represents any symbol character
    function _isAnySimbol(bytes1 character) private pure returns (bool) {
        return ((character >= 0x21 && character <= 0x2F) || /// @dev includes characters from "!" to "/"
            (character >= 0x3A && character <= 0x40) || /// @dev includes characters from ":" to "@"
            (character >= 0x5B && character <= 0x60) || /// @dev includes characters from "[" to "`"
            (character >= 0x7B && character <= 0x7E)); /// @dev includes characters from "{" to "~"
    }

    /// @dev Checks if a byte is valid for email prefix (letters, digits, and specific symbols)
    function _isOnlyEmailPrefixCharacters(
        bytes1 character
    ) private pure returns (bool) {
        return (_isLetter(character) ||
            _isDigit(character) ||
            (character >= 0x21 && character <= 0x2F) || /// @dev includes characters from "!" to "/"
            (character >= 0x3A && character <= 0x3F) || /// @dev includes characters from ":" to "?"
            (character >= 0x5B && character <= 0x60) || /// @dev includes characters from "[" to "`"
            (character >= 0x7B && character <= 0x7E)); /// @dev includes characters from "{" to "~"
    }

    /// @dev Checks if a byte represents a period/dot character (.)
    function _isAPoint(bytes1 character) private pure returns (bool) {
        return character == 0x2E;
    }

    /// @dev Checks if a byte represents an at symbol (@)
    function _isAAt(bytes1 character) private pure returns (bool) {
        return character == 0x40;
    }
}
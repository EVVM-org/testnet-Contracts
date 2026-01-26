// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
░██████████                                                     
    ░██                                                         
    ░█░██░███░███████░██████ ░███████░██    ░█░██░███░██    ░██ 
    ░█░███  ░██    ░██    ░█░██      ░██    ░█░███   ░██    ░██ 
    ░█░██   ░████████░███████░███████░██    ░█░██    ░██    ░██ 
    ░█░██   ░██     ░██   ░██      ░█░██   ░██░██    ░██   ░███ 
    ░█░██    ░███████░█████░█░███████ ░█████░█░██     ░█████░██ 
                                                            ░██ 
                                                      ░███████  
                                                                
████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
            
 * @title Treasury Contract
 * @author Mate labs
 * @notice Treasury for managing deposits and withdrawals in the EVVM ecosystem
 * @dev Secure vault for ETH and ERC20 tokens with EVVM integration and input validation
 */

import {IERC20} from "@evvm/testnet-contracts/library/primitives/IERC20.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/treasury/lib/ErrorsLib.sol";

contract Treasury {
    /// @dev Reference to the EVVM core contract for balance management
    Evvm evvm;

    /**
     * @notice Initialize Treasury with EVVM contract address
     * @param _evvmAddress Address of the EVVM core contract
     */
    constructor(address _evvmAddress) {
        evvm = Evvm(_evvmAddress);
    }

    /**
     * @notice Deposit ETH or ERC20 tokens into the EVVM ecosystem
     * @dev For ETH deposits: token must be address(0) and amount must equal msg.value
     *      For ERC20 deposits: msg.value must be 0 and token must be a valid ERC20 contract
     *      Deposited funds are credited to the user's EVVM balance and can be used for
     *      gasless transactions within the ecosystem.
     * @param token ERC20 token address (use address(0) for ETH deposits)
     * @param amount Token amount to deposit (must match msg.value for ETH deposits)
     * @custom:throws DepositAmountMustBeGreaterThanZero If amount/msg.value is zero
     * @custom:throws InvalidDepositAmount If amount doesn't match msg.value (ETH) or msg.value != 0 (ERC20)
     */
    function deposit(address token, uint256 amount) external payable {
        if (address(0) == token) {
            /// user is sending host native coin
            if (msg.value == 0)
                revert ErrorsLib.DepositAmountMustBeGreaterThanZero();

            if (amount != msg.value) revert ErrorsLib.InvalidDepositAmount();

            evvm.addAmountToUser(msg.sender, address(0), msg.value);
        } else {
            /// user is sending ERC20 tokens

            if (msg.value != 0) revert ErrorsLib.DepositCoinWithToken();

            if (amount == 0)
                revert ErrorsLib.DepositAmountMustBeGreaterThanZero();

            IERC20(token).transferFrom(msg.sender, address(this), amount);
            evvm.addAmountToUser(msg.sender, token, amount);
        }
    }

    /**
     * @notice Withdraw ETH or ERC20 tokens from the EVVM ecosystem
     * @dev Withdraws tokens from the user's EVVM balance back to their wallet.
     *      Principal Tokens cannot be withdrawn through this function - they can
     *      only be transferred via EVVM pay operations.
     * @param token Token address to withdraw (use address(0) for ETH)
     * @param amount Amount of tokens to withdraw
     * @custom:throws PrincipalTokenIsNotWithdrawable If attempting to withdraw Principal Tokens
     * @custom:throws InsufficientBalance If user's EVVM balance is less than withdrawal amount
     */
    function withdraw(address token, uint256 amount) external {
        if (token == evvm.getPrincipalTokenAddress())
            revert ErrorsLib.PrincipalTokenIsNotWithdrawable();

        if (evvm.getBalance(msg.sender, token) < amount)
            revert ErrorsLib.InsufficientBalance();

        if (token == address(0)) {
            /// user is trying to withdraw native coin

            evvm.removeAmountFromUser(msg.sender, address(0), amount);
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            /// user is trying to withdraw ERC20 tokens

            evvm.removeAmountFromUser(msg.sender, token, amount);
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    /**
     * @notice Returns the address of the connected EVVM core contract
     * @dev Used for verification and integration purposes
     * @return Address of the EVVM contract managing balances
     */
    function getEvvmAddress() external view returns (address) {
        return address(evvm);
    }
}

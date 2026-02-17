// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

interface ITreasury {
    error DepositAmountMustBeGreaterThanZero();
    error DepositCoinWithToken();
    error InsufficientBalance();
    error InvalidDepositAmount();
    error PrincipalTokenIsNotWithdrawable();

    function deposit(address token, uint256 amount) external payable;
    function getCoreAddress() external view returns (address);
    function withdraw(address token, uint256 amount) external;
}

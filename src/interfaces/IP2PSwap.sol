// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library P2PSwapStructs {
    struct MarketInformation {
        uint256 maxSlot;
        uint256 ordersAvailable;
        uint256 medianPrice;
    }

    struct Order {
        address seller;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 amountAvailable;
    }

    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    struct WithdrawalProposal {
        address tokenToWithdraw;
        uint256 amountToWithdraw;
        uint256 proposalTime;
    }
}

interface IP2PSwap {
    error IncorrectAddressInput();
    error IncorrectInput();
    error InsufficientAmount();
    error InsufficientAmountToFill();
    error InsufficientPayment();
    error InvalidBasisPoints();
    error InvalidServiceSignature();
    error NotTheSeller();
    error OrderIsUnavailable();
    error ProposalNotReadyToAccept();
    error SameTokenPair();
    error SenderIsNotAdmin();
    error SenderIsNotTheProposedAdmin();
    error UnexpectedBehavior();
    error ZeroAmount();

    function acceptAdmin() external;
    function acceptBasisPercentageFee() external;
    function acceptBasisPointsForReward() external;
    function acceptWithdrawal() external;
    function applyBasisPoints(uint256 amount, uint256 basisPoints) external pure returns (uint256);
    function cancelOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external;
    function dispatchOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external;
    function getAdmin() external view returns (address);
    function getAdminProposal() external view returns (address);
    function getAdminTimeToAccept() external view returns (uint256);
    function getBasisPointsForReward() external view returns (P2PSwapStructs.Percentage memory);
    function getBasisPointsForRewardProposal() external view returns (P2PSwapStructs.Percentage memory);
    function getBasisPointsForRewardProposalTime() external view returns (uint256);
    function getEvvmID() external view returns (uint256);
    function getFeePaymentAmount(uint256 netPaymentAmount) external view returns (uint256);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getMarketId(address tokenA, address tokenB) external pure returns (bytes32);
    function getMarketInformation(bytes32 marketId) external view returns (P2PSwapStructs.MarketInformation memory);
    function getNetPaymentAmount(uint256 amountOut, uint256 offeredAmount, uint256 requestedAmount)
        external
        pure
        returns (uint256);
    function getNextCurrentSyncNonce(address user) external view returns (uint256);
    function getOrder(bytes32 marketId, uint256 orderId) external view returns (P2PSwapStructs.Order memory);
    function getPercentageFee() external view returns (uint256);
    function getPercentageFeeProposal() external view returns (uint256);
    function getPercentageFeeTimeToAccept() external view returns (uint256);
    function getPrincipalTokenAddress() external view returns (address);
    function getTotalFeesCollected(address token) external view returns (uint256);
    function getVWAP(bytes32 marketId) external view returns (uint256);
    function getWithdrawalProposal() external view returns (P2PSwapStructs.WithdrawalProposal memory);
    function makeOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 offeredAmount,
        uint256 requestedAmount,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external;
    function proposeAdmin(address _newOwner) external;
    function proposeBasisPercentageFee(uint256 _newFee) external;
    function proposeBasisPointsForReward(uint256 _seller, uint256 _service, uint256 _mateStaker) external;
    function proposeWithdrawal(address tokenToWithdraw, uint256 amountToWithdraw) external;
    function rejectProposalAdmin() external;
    function rejectProposalBasisPercentageFee() external;
    function rejectProposalBasisPointsForReward() external;
    function rejectProposalWithdrawal() external;
}

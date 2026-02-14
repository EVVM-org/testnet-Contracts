// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library HostChainStationStructs {
    struct AxelarConfig {
        string externalChainStationChainName;
        string externalChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    struct CrosschainConfig {
        HyperlaneConfig hyperlane;
        LayerZeroConfig layerZero;
        AxelarConfig axelar;
    }

    struct HyperlaneConfig {
        uint32 externalChainStationDomainId;
        bytes32 externalChainStationAddress;
        address mailboxAddress;
    }

    struct LayerZeroConfig {
        uint32 externalChainStationEid;
        bytes32 externalChainStationAddress;
        address endpointAddress;
    }
}

library ProposalStructs {
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }
}

interface ITreasuryHostChainStation {
    struct EnforcedOptionParam {
        uint32 eid;
        uint16 msgType;
        bytes options;
    }

    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }

    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error ChainIdNotAuthorized();
    error FailedInnerCall();
    error InsufficientBalance();
    error InvalidAddress();
    error InvalidDelegate();
    error InvalidEndpointCall();
    error InvalidOptionType(uint16 optionType);
    error InvalidOptions(bytes options);
    error LzTokenUnavailable();
    error MailboxNotAuthorized();
    error NoPeer(uint32 eid);
    error NotApprovedByGateway();
    error NotEnoughNative(uint256 msgValue);
    error OnlyEndpoint(address addr);
    error OnlyPeer(uint32 eid, bytes32 sender);
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error PrincipalTokenIsNotWithdrawable();
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeERC20FailedOperation(address token);
    error SenderNotAuthorized();

    event EnforcedOptionSet(EnforcedOptionParam[] _enforcedOptions);
    event FisherBridgeSend(
        address indexed from,
        address indexed addressToReceive,
        address indexed tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PeerSet(uint32 eid, bytes32 peer);

    function _setExternalChainAddress(
        address externalChainStationAddress,
        string memory externalChainStationAddressString
    ) external;
    function acceptAdmin() external;
    function acceptExternalChainAddress() external;
    function acceptFisherExecutor() external;
    function allowInitializePath(Origin memory origin) external view returns (bool);
    function combineOptions(uint32 _eid, uint16 _msgType, bytes memory _extraOptions)
        external
        view
        returns (bytes memory);
    function endpoint() external view returns (address);
    function enforcedOptions(uint32 eid, uint16 msgType) external view returns (bytes memory enforcedOption);
    function execute(bytes32 commandId, string memory sourceChain, string memory sourceAddress, bytes memory payload)
        external;
    function fisherBridgeReceive(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
    function fisherBridgeSend(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
    function gateway() external view returns (address);
    function getAdmin() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getAxelarConfig() external view returns (HostChainStationStructs.AxelarConfig memory);
    function getCoreAddress() external view returns (address);
    function getFisherExecutor() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getHyperlaneConfig() external view returns (HostChainStationStructs.HyperlaneConfig memory);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getLayerZeroConfig() external view returns (HostChainStationStructs.LayerZeroConfig memory);
    function getOptions() external view returns (bytes memory);
    function getQuoteHyperlane(address toAddress, address token, uint256 amount) external view returns (uint256);
    function handle(uint32 _origin, bytes32 _sender, bytes memory _data) external payable;
    function isComposeMsgSender(Origin memory, bytes memory, address _sender) external view returns (bool);
    function lzReceive(
        Origin memory _origin,
        bytes32 _guid,
        bytes memory _message,
        address _executor,
        bytes memory _extraData
    ) external payable;
    function nextNonce(uint32, bytes32) external view returns (uint64 nonce);
    function oAppVersion() external pure returns (uint64 senderVersion, uint64 receiverVersion);
    function owner() external view returns (address);
    function peers(uint32 eid) external view returns (bytes32 peer);
    function proposeAdmin(address _newOwner) external;
    function proposeExternalChainAddress(
        address externalChainStationAddress,
        string memory externalChainStationAddressString
    ) external;
    function proposeFisherExecutor(address _newFisherExecutor) external;
    function quoteLayerZero(address toAddress, address token, uint256 amount) external view returns (uint256);
    function rejectProposalAdmin() external;
    function rejectProposalExternalChainAddress() external;
    function rejectProposalFisherExecutor() external;
    function renounceOwnership() external;
    function setDelegate(address _delegate) external;
    function setEnforcedOptions(EnforcedOptionParam[] memory _enforcedOptions) external;
    function setPeer(uint32 _eid, bytes32 _peer) external;
    function transferOwnership(address newOwner) external;
    function withdraw(address toAddress, address token, uint256 amount, bytes1 protocolToExecute) external payable;
}

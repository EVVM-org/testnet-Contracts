/**
 * Foundry Integration Utilities
 *
 * Provides functions for interacting with Foundry toolchain including:
 * - Contract deployment and verification
 * - Wallet management and validation
 * - Registry contract interactions
 * - Solidity file generation
 *
 * @module cli/utils/foundry
 */

import { $ } from "bun";

import type { CreatedContract, ContractFileMetadata } from "../types";
import {
  colors,
  EthSepoliaPublicRpc,
  RegisteryEvvmAddress,
  ChainData,
} from "../constants";
import {
  confirmation,
  criticalError,
  criticalErrorCustom,
  warning,
  createLoadingAnimation,
  seccionTitle,
} from "./outputMesages";
import { getAddress } from "viem/utils";
import {
  saveCrossChainDeploymentToJson,
  saveDeploymentToJson,
} from "./outputJson";
import { promptSelect } from "./prompts";
import { checkDirectoryPath, writeFilePath } from "./fileManagement";

/**
 * Checks if a chain ID is registered in the EVVM Registry
 *
 * Queries the EVVM Registry contract on Ethereum Sepolia to verify if the
 * target chain ID is supported for EVVM deployments.
 *
 * @param {number} chainId - The chain ID to check
 * @returns {Promise<boolean | undefined>} True if registered, false if not, undefined on error
 */
export async function isChainIdRegistered(chainId: number): Promise<boolean> {
  let isSupported: boolean = false;
  const ethRpcUrl =
    process.env.EVVM_REGISTRATION_RPC_URL?.trim() || EthSepoliaPublicRpc;
  try {
    const result =
      await $`cast call ${RegisteryEvvmAddress} --rpc-url ${ethRpcUrl} "isChainIdRegistered(uint256)(bool)" ${chainId}`.quiet();
    isSupported = result.stdout.toString().trim() === "true";
  } catch (error) {
    criticalError(`Failed to check chain ID ${chainId} registration status.`);
  }
  return isSupported;
}

/**
 * Registers an EVVM instance in the EVVM Registry contract
 *
 * Calls the registry contract to register the EVVM instance and receive a unique
 * EVVM ID. This ID is used to identify the EVVM instance across the ecosystem.
 *
 * @param {number} hostChainId - Chain ID where the EVVM is deployed
 * @param {`0x${string}`} coreAddress - Address of the deployed EVVM contract
 * @param {string} walletName - Foundry wallet name to use for the transaction
 * @param {string} ethRpcUrl - Ethereum Sepolia RPC URL for registry interaction
 * @returns {Promise<number | undefined>} The assigned EVVM ID, or undefined on error
 */
export async function callRegisterEvvm(
  hostChainId: number,
  coreAddress: string,
  walletName: string = "defaultKey",
  ethRpcUrl: string = EthSepoliaPublicRpc
): Promise<number | undefined> {
  let evvmID: string = "";

  try {
    const result =
      await $`cast call ${RegisteryEvvmAddress} --rpc-url ${ethRpcUrl} "registerEvvm(uint256,address)(uint256)" ${hostChainId} ${coreAddress} --account ${walletName}`.quiet();


    await castSend(
      RegisteryEvvmAddress as `0x${string}`,
      ethRpcUrl,
      "registerEvvm(uint256,address)(uint256)",
      [hostChainId.toString(), coreAddress],
      walletName
    );

    evvmID = result.stdout.toString().trim();

    return Number(evvmID);
  } catch (error) {
    criticalError(`Failed to register EVVM on chain ID ${hostChainId}.`);
  }
}

/**
 * Sets the EVVM ID on the deployed EVVM contract
 *
 * After receiving an EVVM ID from the registry, this function updates the
 * EVVM contract with its assigned ID. Required to complete EVVM initialization.
 *
 * @param {`0x${string}`} coreAddress - Address of the EVVM contract
 * @param {number} evvmID - The EVVM ID assigned by the registry
 * @param {string} hostChainRpcUrl - RPC URL for the chain where EVVM is deployed
 * @param {string} walletName - Foundry wallet name to use for the transaction
 * @returns {Promise<boolean>} True if successfully set, false on error
 */
export async function callSetEvvmID(
  contractAddress: string,
  evvmID: number,
  hostChainRpcUrl: string,
  walletName: string = "defaultKey"
) {
  try {
    await castSend(
      contractAddress as `0x${string}`,
      hostChainRpcUrl,
      "setEvvmID(uint256)",
      [evvmID.toString()],
      walletName
    );
  } catch (error) {
    criticalErrorCustom(
      `EVVM ID setting failed.`,
      `\n${colors.yellow}You can try manually with:${colors.reset}\n${colors.blue}cast send ${contractAddress} \\\n  --rpc-url <rpc-url> \\\n  "setEvvmID(uint256)" ${evvmID} \\\n  --account ${walletName}${colors.reset}`
    );
  }
}

/**
 * Establishes bidirectional connection between host and external chain treasury stations
 *
 * Creates the cross-chain link by:
 * 1. Setting external station address on the host station contract
 * 2. Setting host station address on the external station contract
 *
 * This bidirectional connection enables cross-chain asset transfers and
 * communication between the two treasury stations.
 *
 * @param {string} treasuryHostChainStationAddress - Address of Host Chain Station contract
 * @param {string} hostChainRpcUrl - RPC URL for the host chain
 * @param {string} [hostWalletName="defaultKey"] - Foundry wallet for host chain transactions
 * @param {string} treasuryExternalChainAddress - Address of External Chain Station contract
 * @param {string} externalChainRpcUrl - RPC URL for the external chain
 * @param {string} [externalWalletName="defaultKey"] - Foundry wallet for external chain transactions
 * @returns {Promise<void>} Resolves when both connections are established
 * @throws {Error} Exits process if connection fails on either chain
 */
export async function callConnectStations(
  treasuryHostChainStationAddress: string,
  hostChainRpcUrl: string,
  hostWalletName: string = "defaultKey",
  treasuryExternalChainAddress: string,
  externalChainRpcUrl: string,
  externalWalletName: string = "defaultKey"
) {
  try {
    console.log(
      `${colors.bright}→ Establishing connection: Host Station → External Station...${colors.reset}`
    );

    await castSend(
      treasuryHostChainStationAddress as `0x${string}`,
      hostChainRpcUrl,
      "_setExternalChainAddress(address,string)",
      [
        treasuryExternalChainAddress,
        `"${getAddress(treasuryExternalChainAddress)}"`,
      ],
      hostWalletName
    );

    confirmation("Host Station → External Station connection established.");

    console.log(
      `${colors.bright}→ Establishing connection: External Station → Host Station...${colors.reset}`
    );

    await castSend(
      treasuryExternalChainAddress as `0x${string}`,
      externalChainRpcUrl,
      "_setHostChainAddress(address,string)",
      [
        treasuryHostChainStationAddress,
        `"${getAddress(treasuryHostChainStationAddress)}"`,
      ],
      externalWalletName
    );

    confirmation("External Station → Host Station connection established.");
  } catch (error) {
    criticalError(`Failed to connect treasury stations.`);
  }
}

/**
 * Executes a contract transaction using Foundry's cast send
 *
 * Automatically detects network requirements and adds appropriate flags:
 * - Legacy transaction format for networks with gas price = 0
 * - Gas limit of 500000 for legacy transactions
 *
 * This is a low-level utility function used by other functions to
 * interact with deployed contracts.
 *
 * @param {`0x${string}`} addressToCall - Contract address to interact with
 * @param {string} rpcUrl - RPC endpoint URL for the target blockchain
 * @param {string} functionSignature - Solidity function signature (e.g., "transfer(address,uint256)")
 * @param {string[]} args - Array of function arguments as strings
 * @param {string} [walletName="defaultKey"] - Foundry wallet name for signing
 * @returns {Promise<boolean>} True if transaction succeeded, false on error
 *
 * @example
 * ```typescript
 * await castSend(
 *   "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
 *   "https://rpc.sepolia.org",
 *   "setEvvmID(uint256)",
 *   ["1234"],
 *   "myWallet"
 * );
 * ```
 */
export async function castSend(
  addressToCall: `0x${string}`,
  rpcUrl: string,
  functionSignature: string,
  args: string[],
  walletName: string = "defaultKey"
): Promise<boolean> {
  try {
    const command = [
      "cast",
      "send",
      addressToCall,
      "--rpc-url",
      rpcUrl,
      functionSignature,
      ...args,
      "--account",
      walletName,
    ];

    if (await shouldUseLegacy(rpcUrl)) {
      command.push("--legacy");
      command.push("--gas-limit", "500000");
    }

    await $`${command}`;

    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Detects if the network requires legacy transaction type
 *
 * Checks if the RPC endpoint supports EIP-1559 or requires legacy transactions.
 * Returns true if gas price is 0 or if the network doesn't support EIP-1559.
 *
 * @param {string} rpcUrl - RPC endpoint URL to check
 * @returns {Promise<boolean>} True if legacy transactions should be used
 */
export async function shouldUseLegacy(rpcUrl: string): Promise<boolean> {
  try {
    // Check gas price - if it's 0, use legacy transactions
    const gasPriceResult = await $`cast gas-price --rpc-url ${rpcUrl}`.quiet();
    const gasPrice = gasPriceResult.stdout.toString().trim();

    if (gasPrice === "0") {
      warning("Using legacy transaction type", "Gas price is 0");
      return true;
    }

    // Try to get the latest block's baseFeePerGas
    const blockResult =
      await $`cast block latest --rpc-url ${rpcUrl} --json`.quiet();
    const block = JSON.parse(blockResult.stdout.toString());

    // If baseFeePerGas is missing or 0, the network doesn't support EIP-1559
    if (!block.baseFeePerGas || block.baseFeePerGas === "0x0") {
      warning(
        "Using legacy transaction type",
        "Network doesn't support EIP-1559"
      );
      return true;
    }

    return false;
  } catch (error) {
    // If we can't determine, default to not using legacy
    console.log(
      `${colors.darkGray}ℹ  Unable to detect transaction type - using default${colors.reset}`
    );
    return false;
  }
}

/**
 * Detects the optimal EVM version for the target network
 *
 * Attempts to determine the best EVM version to use for compilation
 * based on network characteristics and capabilities.
 *
 * @param {string} rpcUrl - RPC endpoint URL to check
 * @returns {Promise<string | null>} EVM version to use, or null for default
 */
export async function detectEvmVersion(rpcUrl: string): Promise<string | null> {
  try {
    const blockResult =
      await $`cast block latest --rpc-url ${rpcUrl} --json`.quiet();
    const block = JSON.parse(blockResult.stdout.toString());

    // Check for EIP-1559 support (London and later)
    if (block.baseFeePerGas && block.baseFeePerGas !== "0x0") {
      return null; // Use default (latest)
    }

    // If no baseFeePerGas, likely pre-London
    warning(
      "Network appears to be pre-London EVM version (no EIP-1559 support).",
      "Using 'london' for compatibility"
    );
    return "london";
  } catch (error) {
    // If detection fails, return null to use default
    return null;
  }
}

/**
 * Executes a Foundry deployment script with automatic network optimization
 *
 * Runs a Forge script with the following automatic configurations:
 * - Via-IR compilation for gas optimization
 * - Legacy transaction detection for networks without EIP-1559
 * - EVM version detection for compatibility
 * - Optional block explorer verification
 *
 * The function cleans the build cache before execution to ensure
 * a fresh deployment state.
 *
 * @param {string} scriptPath - Path to the Solidity script (e.g., "script/Deploy.s.sol:DeployScript")
 * @param {string} rpcUrl - RPC endpoint URL for the target blockchain
 * @param {string} [walletName="defaultKey"] - Foundry wallet name for deployment transactions
 * @param {string[]} [verificationArgs=[]] - Additional arguments for block explorer verification
 * @returns {Promise<void>} Resolves when deployment completes successfully
 * @throws {Error} Exits process if deployment fails
 *
 * @example
 * ```typescript
 * await forgeScript(
 *   "script/Deploy.s.sol:DeployScript",
 *   "https://rpc.sepolia.org",
 *   "defaultKey",
 *   ["--verify", "--etherscan-api-key", "YOUR_KEY"]
 * );
 * ```
 */
export async function forgeScript(
  scriptPath: string,
  rpcUrl: string,
  walletName: string = "defaultKey",
  verificationArgs: string[] = []
) {
  try {
    const command = [
      "forge",
      "script",
      scriptPath,
      "--via-ir",
      "--optimize",
      "true",
      "--rpc-url",
      rpcUrl,
      "--account",
      walletName,
      ...verificationArgs,
      "--broadcast",
      "-vvvv",
    ];

    if (await shouldUseLegacy(rpcUrl)) {
      command.push("--legacy");
    }

    const evmVersion = await detectEvmVersion(rpcUrl);
    if (evmVersion) {
      command.push("--evm-version", evmVersion);
    }

    await $`forge clean`.quiet();

    await $`${command}`;

    confirmation("Deployment script executed successfully.");
  } catch (error) {
    criticalError(`Deployment failed.`);
  }
}

/**
 * Verifies Foundry installation and wallet setup
 *
 * Performs prerequisite checks before deployment:
 * 1. Verifies Foundry toolchain is installed
 * 2. Verifies the specified wallet exists in Foundry keystore
 *
 * @param {string} walletName - Name of the wallet to verify
 * @returns {Promise<boolean>} True if all prerequisites are met, false otherwise
 */
export async function verifyFoundryInstalledAndAccountSetup(
  walletNames: string[] = ["defaultKey"]
) {
  if (!(await foundryIsInstalled()))
    criticalErrorCustom(
      "Foundry installation not detected.",
      "Visit https://getfoundry.sh/ for installation instructions."
    );

  const walletSetupResults = await walletIsSetup(walletNames);
  for (let i = 0; i < walletNames.length; i++) {
    if (!walletSetupResults[i]) {
      criticalErrorCustom(
        `Wallet '${walletNames[i]}' is not available.`,
        `Please import your wallet using:\n   ${colors.evvmGreen}cast wallet import ${walletNames[i]} --interactive${colors.reset}\n\n   You'll be prompted to enter your private key securely.`
      );
    }
  }
}

/**
 * Checks if Foundry toolchain is installed
 *
 * @returns {Promise<boolean>} True if Foundry is installed and accessible
 */
export async function foundryIsInstalled(): Promise<boolean> {
  try {
    await $`foundryup --version`.quiet();
  } catch (error) {
    return false;
  }
  return true;
}

/**
 * Checks if a wallet exists in Foundry's keystore
 *
 * @param {string} walletName - Name of the wallet to check
 * @returns {Promise<boolean>} True if wallet exists in keystore
 */
export async function walletIsSetup(
  walletNames: string[] = ["defaultKey"]
): Promise<boolean[]> {
  let walletList = await $`cast wallet list`.quiet();

  const walletListStr = walletList.stdout.toString();

  const results: boolean[] = walletNames.map((walletName) =>
    walletListStr.includes(`${walletName} (Local)`)
  );

  return results;
}

/**
 * Displays deployed contracts and extracts EVVM contract address
 *
 * Reads the Foundry broadcast file to:
 * 1. Extract all deployed contract addresses
 * 2. Display them in a formatted list
 * 3. Locate and return the EVVM contract address
 *
 * @param {number} chainId - Chain ID where contracts were deployed
 * @returns {Promise<`0x${string}` | null>} EVVM contract address, or null if not found
 */
export async function showDeployContractsAndFindEvvm(
  chainId: number
): Promise<`0x${string}` | null> {
  const {
    start: startGettingDeployedContractsAnimation,
    stop: stopGettingDeployedContractsAnimation,
  } = createLoadingAnimation(`Getting deployed contracts data...`, "dots13");

  startGettingDeployedContractsAnimation();
  const broadcastFile = `./broadcast/Deploy.s.sol/${chainId}/run-latest.json`;
  const broadcastContent = await Bun.file(broadcastFile).text();
  const broadcastJson = JSON.parse(broadcastContent);
  await stopGettingDeployedContractsAnimation(500);

  const {
    start: startSearchDeployedContractsAnimation,
    stop: stopSearchDeployedContractsAnimation,
  } = createLoadingAnimation(`Searching deployed contracts...`, "growVertical");

  startSearchDeployedContractsAnimation();
  const createdContracts = broadcastJson.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );
  await stopSearchDeployedContractsAnimation(500);

  seccionTitle("Deployed Contracts");

  const chainData = ChainData[chainId];
  const explorerUrl = chainData?.ExplorerUrl;

  createdContracts.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrl) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrl}${contract.contractAddress}`
      );
    }
  });
  console.log();

  await saveDeploymentToJson(createdContracts, chainId, chainData?.Chain);

  return (
    createdContracts.find(
      (contract: CreatedContract) => contract.contractName === "Evvm"
    )?.contractAddress ?? null
  );
}

/**
 * Displays deployed cross-chain contracts and extracts key addresses
 *
 * Reads Foundry broadcast files from both host and external chain deployments
 * to display all deployed contracts and extract the addresses of:
 * - EVVM core contract (host chain)
 * - TreasuryHostChainStation contract (host chain)
 * - TreasuryExternalChainStation contract (external chain)
 *
 * Also saves deployment information to JSON file for record-keeping.
 *
 * @param {number} chainIdHost - Chain ID where host contracts were deployed
 * @param {number} chainIdExternal - Chain ID where external contracts were deployed
 * @returns {Promise<Object>} Object containing extracted contract addresses:
 *   - coreAddress: EVVM core contract address (or null if not found)
 *   - treasuryHostChainStationAddress: Host station address (or null if not found)
 *   - treasuryExternalChainStationAddress: External station address (or null if not found)
 *
 * @example
 * ```typescript
 * const { coreAddress, treasuryHostChainStationAddress, treasuryExternalChainStationAddress } =
 *   await showAllCrossChainDeployedContracts(11155111, 421614);
 * ```
 */
export async function showAllCrossChainDeployedContracts(
  chainIdHost: number,
  chainIdExternal: number
): Promise<{
  coreAddress: `0x${string}` | null;
  treasuryHostChainStationAddress: `0x${string}` | null;
  treasuryExternalChainStationAddress: `0x${string}` | null;
}> {
  const {
    start: startGettingDeployedContractsAnimation,
    stop: stopGettingDeployedContractsAnimation,
  } = createLoadingAnimation(`Getting deployed contracts data...`, "dots13");
  startGettingDeployedContractsAnimation();
  const broadcastFileHost = `./broadcast/DeployCrossChainHost.s.sol/${chainIdHost}/run-latest.json`;
  const broadcastContentHost = await Bun.file(broadcastFileHost).text();
  const broadcastJsonHost = JSON.parse(broadcastContentHost);

  const broadcastFileExternal = `./broadcast/DeployCrossChainExternal.s.sol/${chainIdExternal}/run-latest.json`;
  const broadcastContentExternal = await Bun.file(broadcastFileExternal).text();
  const broadcastJsonExternal = JSON.parse(broadcastContentExternal);
  await stopGettingDeployedContractsAnimation(500);

  const {
    start: startSearchDeployedContractsAnimation,
    stop: stopSearchDeployedContractsAnimation,
  } = createLoadingAnimation(`Searching deployed contracts...`, "growVertical");

  startSearchDeployedContractsAnimation();
  const createdContractsHost = broadcastJsonHost.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );

  const createdContractsExternal = broadcastJsonExternal.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );
  await stopSearchDeployedContractsAnimation(500);

  seccionTitle(
    "Deployed Contracts",
    ChainData[chainIdHost]?.Chain || chainIdHost.toString()
  );

  const chainDataHost = ChainData[chainIdHost];
  const explorerUrlHost = chainDataHost?.ExplorerUrl;

  createdContractsHost.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrlHost) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrlHost}${contract.contractAddress}`
      );
    }
  });

  console.log();

  seccionTitle(
    "Deployed Contracts",
    ChainData[chainIdExternal]?.Chain || chainIdExternal.toString()
  );

  const chainDataExternal = ChainData[chainIdExternal];
  const explorerUrlExternal = chainDataExternal?.ExplorerUrl;

  createdContractsExternal.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrlExternal) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrlExternal}${contract.contractAddress}`
      );
    }
  });

  console.log();

  await saveCrossChainDeploymentToJson(
    createdContractsHost,
    chainIdHost,
    ChainData[chainIdHost]?.Chain || undefined,
    createdContractsExternal,
    chainIdExternal,
    ChainData[chainIdExternal]?.Chain || undefined
  );

  const coreAddress =
    createdContractsHost.find(
      (contract: CreatedContract) => contract.contractName === "Evvm"
    )?.contractAddress ?? null;

  const treasuryHostChainStationAddress =
    createdContractsHost.find(
      (contract: CreatedContract) =>
        contract.contractName === "TreasuryHostChainStation"
    )?.contractAddress ?? null;

  const treasuryExternalChainStationAddress =
    createdContractsExternal.find(
      (contract: CreatedContract) =>
        contract.contractName === "TreasuryExternalChainStation"
    )?.contractAddress ?? null;

  return {
    coreAddress,
    treasuryHostChainStationAddress,
    treasuryExternalChainStationAddress,
  };
}

/**
 * Generates Solidity interfaces for EVVM contracts
 *
 * Uses Foundry's `cast interface` command to create interface files for
 * all core EVVM contracts. Interfaces are saved in the `src/interfaces` directory.
 *
 * @returns {Promise<void>} Resolves when interfaces are generated
 */
export async function contractInterfacesGenerator() {
  const contractName = await promptSelect(
    "Select contract to make interface for:",
    [
      "Core",
      "NameService",
      "P2PSwap",
      "Staking",
      "Estimator",
      "Treasury",
      "TreasuryExternalChainStation",
      "TreasuryHostChainStation",
      "All Contracts",
    ]
  );

  const generateOnlyOne: boolean = contractName !== "All Contracts";

  let contracts: ContractFileMetadata[] = [
    {
      contractName: "Core",
      folderName: "core",
    },
    {
      contractName: "NameService",
      folderName: "nameService",
    },
    {
      contractName: "P2PSwap",
      folderName: "p2pSwap",
    },
    {
      contractName: "Staking",
      folderName: "staking",
    },
    {
      contractName: "Estimator",
      folderName: "staking",
    },
    {
      contractName: "Treasury",
      folderName: "treasury",
    },
    {
      contractName: "TreasuryExternalChainStation",
      folderName: "treasuryTwoChains",
    },
    {
      contractName: "TreasuryHostChainStation",
      folderName: "treasuryTwoChains",
    },
  ];

  const fs = require("fs");
  const path = "./src/interfaces";

  await checkDirectoryPath(path);

  if (generateOnlyOne) {
    const folderName = contracts.find(
      (c) => c.contractName === contractName
    )?.folderName;

    if (!folderName) {
      criticalError(`Contract '${contractName}' not found in metadata.`);
    }
    const {
      start: startGeneratingInterfacesAnimation,
      stop: stopGeneratingInterfacesAnimation,
    } = createLoadingAnimation(
      `Generating interface for ${contractName}...`,
      "growVertical"
    );

    startGeneratingInterfacesAnimation();
    const evvmInterface =
      await $`cast interface src/contracts/${folderName}/${contractName}.sol`.quiet();
    const interfacePath = `./src/interfaces/I${contractName}.sol`;

    let content = evvmInterface.stdout
      .toString()
      .replace(
        /^\/\/ SPDX-License-Identifier:.*$/m,
        "// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0\n// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense"
      )
      .replace("pragma solidity ^0.8.4;", "pragma solidity ^0.8.0;")
      .replace(`interface ${contractName} {`, `interface I${contractName} {`);
    await stopGeneratingInterfacesAnimation(1500);

    await writeFilePath(interfacePath, content);

    confirmation(`I${contractName}.sol generated at ${interfacePath}`);
  } else {
    for (const contract of contracts) {
      const {
        start: startGeneratingInterfacesAnimation,
        stop: stopGeneratingInterfacesAnimation,
      } = createLoadingAnimation(
        `Generating interface for ${contract.contractName}...`,
        "growVertical"
      );

      startGeneratingInterfacesAnimation();
      let evvmInterface =
        await $`cast interface src/contracts/${contract.folderName}/${contract.contractName}.sol`.quiet();
      let interfacePath = `./src/interfaces/I${contract.contractName}.sol`;

      // Process and clean the interface content
      let content = evvmInterface.stdout
        .toString()
        .replace(
          /^\/\/ SPDX-License-Identifier:.*$/m,
          "// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0\n// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense"
        )
        .replace("pragma solidity ^0.8.4;", "pragma solidity ^0.8.0;")
        .replace(
          `interface ${contract.contractName} {`,
          `interface I${contract.contractName} {`
        );

      await stopGeneratingInterfacesAnimation(1500);
      await writeFilePath(interfacePath, content);

      confirmation(
        `I${contract.contractName}.sol generated at ${interfacePath}`
      );
    }
  }
  console.log();
  confirmation("Contract interface generation completed");
}

export async function contractTesting() {
  const contractName: string = await promptSelect("Select contract to test:", [
    "Core",
    "NameService",
    "P2PSwap",
    "Staking",
    "Estimator",
    "Treasury",
    "All Contracts",
  ]);

  const testType: string = await promptSelect("Select test type:", [
    "unit correct",
    "unit revert",
    "fuzzing",
    "full test suite",
  ]);

  // Build a compact name filter: prefix with '_' when a specific contract is selected
  const nameFilterPart =
    contractName === "All Contracts" ? "" : `_${contractName}`;

  let testNameFilter: string;
  switch (testType) {
    case "unit correct":
      testNameFilter = `unitTestCorrect${nameFilterPart}`;
      break;
    case "unit revert":
      testNameFilter = `unitTestRevert${nameFilterPart}`;
      break;
    case "fuzzing":
      testNameFilter = `fuzzTest${nameFilterPart}`;
      break;
    case "full test suite":
      // For full test suite we match the contract name (if provided) or run all tests
      testNameFilter = nameFilterPart; // may be empty to run all
      break;
    default:
      testNameFilter = "";
  }

  const print: string = await promptSelect("Select output format:", [
    "markdown",
    "json",
    "none",
  ]);

  let printCommand: string;
  switch (print) {
    case "markdown":
      printCommand = `--show-progress --md`;
      break;
    case "json":
      printCommand = `--json`;
      break;
    case "none":
      printCommand = `--show-progress`;
      break;
    default:
      printCommand = "";
  }

  // Build command arguments array for Bun $ execution (avoids running a single string as an executable)
  const command: string[] = ["forge", "test"];
  if (testNameFilter && testNameFilter.trim() !== "") {
    command.push("--match-contract", testNameFilter);
  }
  command.push("--summary", "--detailed", "--gas-report", "-vvv");
  if (printCommand && printCommand.trim() !== "") {
    const printParts = printCommand.split(" ");
    command.push(...printParts);
  }

  console.log(
    `${colors.darkGray}running\n${command.join(" ")}${colors.reset}\n`
  );

  const { start: startTestAnimation, stop: stopTestAnimation } =
    createLoadingAnimation(
      `Executing ${contractName} ${
        testType !== "full test suite" ? `${testType} tests` : testType
      }...`,
      "runner"
    );

  if (print === "json" || print === "markdown") {
    const path = "./output/testResults";

    await checkDirectoryPath(path);

    startTestAnimation();

    const result = await $`${command}`.quiet();

    await stopTestAnimation();

    const {
      start: startPreparingTestAnimation,
      stop: stopPreparingTestAnimation,
    } = createLoadingAnimation(
      `Preparing ${contractName} ${
        testType !== "full test suite" ? `${testType} tests` : testType
      } results...`,
      "layer"
    );

    startPreparingTestAnimation();
    const outputContent = result.stdout.toString();
    const fileExtension = print === "json" ? "json" : "md";
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-"); // Replace colon and dot for filename safety
    const outputPath = `${path}/test-results-${timestamp}.${fileExtension}`;
    await stopPreparingTestAnimation(500);

    await writeFilePath(outputPath, outputContent);

    confirmation(`Test results saved to ${outputPath}`);
  } else {
    await $`${command}`;
  }
}

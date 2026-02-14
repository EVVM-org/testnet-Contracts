/**
 * Output JSON Utilities
 *
 * Provides functions for saving deployment information to JSON files.
 * Creates and manages the output directory for storing deployment artifacts.
 *
 * @module cli/utils/outputJson
 */

import { join } from "path";
import type { CreatedContract } from "../types";
import { colors } from "../constants";
import { confirmation, warning } from "./outputMesages";
import { checkDirectoryPath, writeFilePath } from "./fileManagement";

/**
 * Base function to write JSON data to the output directory
 *
 * Handles the common logic for all JSON output operations:
 * - Creates output directory if it doesn't exist
 * - Writes data to specified file with pretty formatting
 * - Provides confirmation or error messages
 *
 * @param {string} fileName - Name of the file (without .json extension)
 * @param {any} data - Data object to be serialized to JSON
 * @param {string} operationName - Description of the operation for logging
 * @returns {Promise<void>} Resolves when file is successfully written
 */
async function writeJsonToOutput(
  fileName: string,
  data: any,
  operationName: string
): Promise<void> {

  try {
    const outputDir = "./output/deployments";

    await checkDirectoryPath(outputDir);

    // Construct file path
    const filePath = join(outputDir, `${fileName}.json`);

    // Write to file with pretty formatting
    await writeFilePath(filePath, JSON.stringify(data, null, 2));

    confirmation(
      `${operationName} saved to: ${colors.blue}${filePath}${colors.reset}`
    );
  } catch (err) {
    warning(
      `Failed to save ${operationName}`,
      `${err instanceof Error ? err.message : "Unknown error"}`
    );
  }
}

/**
 * Saves deployed contracts to a JSON file in the output directory
 *
 * Creates the output directory if it doesn't exist, then saves all deployed
 * contract information to a JSON file with the specified name. The file
 * includes metadata such as deployment timestamp and chain information.
 *
 * @param {CreatedContract[]} contracts - Array of deployed contracts with names and addresses
 * @param {number} chainId - Chain ID where contracts were deployed
 * @param {string} [chainName] - Optional human-readable chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * const contracts = [
 *   { contractName: "Core", contractAddress: "0x..." },
 *   { contractName: "Staking", contractAddress: "0x..." }
 * ];
 * await saveDeploymentToJson("my-deployment", contracts, 11155111, "Sepolia");
 * // Creates: ./output/my-deployment.json
 * ```
 */
export async function saveDeploymentToJson(
  contracts: CreatedContract[],
  chainId: number,
  chainName?: string
): Promise<void> {
  const outputData = {
    timestamp: new Date().toISOString(),
    chain: {
      chainId,
      chainName: chainName || `Chain ${chainId}`,
    },
    contracts: contracts.map((contract) => ({
      name: contract.contractName,
      address: contract.contractAddress,
    })),
  };

  await writeJsonToOutput(
    "evvmDeployment",
    outputData,
    "Deployment information"
  );
}

/**
 * Saves cross-chain deployment to a JSON file
 *
 * Similar to saveDeploymentToJson but handles deployments across two chains
 * (host and external). Organizes contracts by chain and includes metadata
 * for both chains.
 *
 * @param {CreatedContract[]} hostContracts - Contracts deployed on host chain
 * @param {number} hostChainId - Host chain ID
 * @param {string} [hostChainName] - Optional host chain name
 * @param {CreatedContract[]} externalContracts - Contracts deployed on external chain
 * @param {number} externalChainId - External chain ID
 * @param {string} [externalChainName] - Optional external chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * await saveCrossChainDeploymentToJson(
 *   "cross-chain-treasury",
 *   hostContracts, 11155111, "Sepolia",
 *   externalContracts, 421614, "Arbitrum Sepolia"
 * );
 * // Creates: ./output/cross-chain-treasury.json
 * ```
 */
export async function saveCrossChainDeploymentToJson(
  hostContracts: CreatedContract[],
  hostChainId: number,
  hostChainName: string | undefined,
  externalContracts: CreatedContract[],
  externalChainId: number,
  externalChainName: string | undefined
): Promise<void> {
  const outputData = {
    deploymentType: "cross-chain",
    timestamp: new Date().toISOString(),
    hostChain: {
      chainId: hostChainId,
      chainName: hostChainName || `Chain ${hostChainId}`,
      contracts: hostContracts.map((contract) => ({
        name: contract.contractName,
        address: contract.contractAddress,
      })),
    },
    externalChain: {
      chainId: externalChainId,
      chainName: externalChainName || `Chain ${externalChainId}`,
      contracts: externalContracts.map((contract) => ({
        name: contract.contractName,
        address: contract.contractAddress,
      })),
    },
  };

  await writeJsonToOutput(
    "evvmCrossChainDeployment",
    outputData,
    "Cross-chain deployment information"
  );
}

/**
 * Saves EVVM registration information to a JSON file
 *
 * Records the EVVM ID assignment and contract address to a JSON file after
 * successful registration with the EVVM Registry. Includes chain information
 * and timestamp for record-keeping.
 *
 * @param {number} evvmID - Unique EVVM ID assigned by the registry
 * @param {`0x${string}`} coreAddress - Address of the registered Core contract
 * @param {number} chainId - Chain ID where EVVM is deployed
 * @param {string} [chainName] - Optional human-readable chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * await saveEvvmRegistrationToJson(
 *   1234,
 *   "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
 *   11155111,
 *   "Sepolia"
 * );
 * // Creates: ./output/evvmRegistration.json
 * ```
 */
export async function saveEvvmRegistrationToJson(
  evvmID: number,
  coreAddress: `0x${string}`,
  chainId: number,
  chainName?: string
): Promise<void> {
  const outputData = {
    timestamp: new Date().toISOString(),
    chain: {
      chainId,
      chainName: chainName || `Chain ${chainId}`,
    },
    evvm: {
      evvmID,
      coreAddress,
    },
  };

  await writeJsonToOutput(
    "evvmRegistration",
    outputData,
    "EVVM registration information"
  );
}

/**
 * Saves cross-chain EVVM registration information to a JSON file
 *
 * Records EVVM ID assignment for a cross-chain deployment, including both
 * the host chain EVVM contract and external chain treasury station addresses.
 * Both contracts share the same EVVM ID for cross-chain coordination.
 *
 * @param {number} evvmID - Unique EVVM ID assigned by the registry
 * @param {`0x${string}`} coreAddress - Address of the Core contract on host chain
 * @param {number} hostChainId - Host chain ID
 * @param {`0x${string}`} treasuryExternalStationAddress - Address of treasury station on external chain
 * @param {number} externalChainId - External chain ID
 * @param {string} [hostChainName] - Optional host chain name
 * @param {string} [externalChainName] - Optional external chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * await saveEvvmCrossChainRegistrationToJson(
 *   1234,
 *   "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
 *   11155111,
 *   "0x1234567890123456789012345678901234567890",
 *   421614,
 *   "Sepolia",
 *   "Arbitrum Sepolia"
 * );
 * // Creates: ./output/evvmCrossChainRegistration.json
 * ```
 */
export async function saveEvvmCrossChainRegistrationToJson(
  evvmID: number,
  coreAddress: `0x${string}`,
  hostChainId: number,
  treasuryExternalStationAddress: `0x${string}`,
  externalChainId: number,

  hostChainName?: string,
  externalChainName?: string
): Promise<void> {
  const outputData = {
    timestamp: new Date().toISOString(),
    hostChain: {
      chainId: hostChainId,
      chainName: hostChainName || `Chain ${hostChainId}`,
    },
    externalChain: {
      chainId: externalChainId,
      chainName: externalChainName || `Chain ${externalChainId}`,
    },
    evvm: {
      evvmID,
      coreAddress,
      treasuryExternalStationAddress,
    },
  };

  await writeJsonToOutput(
    "evvmCrossChainRegistration",
    outputData,
    "EVVM cross-chain registration information"
  );
}

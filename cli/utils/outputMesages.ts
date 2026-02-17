/**
 * Output formatting utilities for the EVVM CLI
 *
 * Provides standardized error, warning, and confirmation message formatting
 * with color support for enhanced terminal output readability.
 *
 * @module cli/utils/outputMesages
 */

import { colors } from "../constants";
import type {
  BaseInputAddresses,
  ChainData,
  CrossChainInputs,
  EvvmMetadata,
} from "../types";

/**
 * Creates a loading animation with auto-clearing and optional timeout on stop
 *
 * @param {string} message - Message to display during animation
 * @param {string} [spinnerType="bouncingBar"] - Spinner style from cli-spinners
 * @param {number} [stopTimeout=0] - Milliseconds to wait before stopping animation
 * @returns {Object} Object with start and stop functions
 */
export function createLoadingAnimation(
  message: string,
  spinnerType: string = "bouncingBar",
  stopTimeout: number = 0
): {
  start: () => void;
  stop: (timeout?: number) => Promise<void>;
} {
  const { loading } = require("cli-loading-animation");
  const spinners = require("cli-spinners");

  const spinnerConfig = spinners[spinnerType] || spinners.bouncingBar;

  const { start, stop: originalStop } = loading(` ${message}`, {
    clearOnEnd: true,
    spinner: spinnerConfig,
  });

  const stop = (timeout: number = stopTimeout) => {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        originalStop();
        resolve();
      }, timeout);
    });
  };

  return { start, stop };
}

export function seccionTitle(title: string, subTitle?: string) {
  console.log();
  if (subTitle) {
    console.log(
      `${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬${colors.reset} ${title} ${colors.evvmGreen}▬▬${colors.reset} ${subTitle} ${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬${colors.reset}`
    );
  } else {
    console.log(
      `${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬${colors.reset} ${title} ${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬${colors.reset}`
    );
  }
  console.log();
}

export function sectionSubtitle(title: string, subTitle?: string) {
  console.log();
  if (subTitle) {
    console.log(
      `${colors.evvmGreen}▬▬${colors.reset} ${title} ${colors.evvmGreen}▬▬${colors.reset} ${subTitle} ${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬${colors.reset}`
    );
  } else {
    console.log(
      `${colors.evvmGreen}▬▬${colors.reset} ${title} ${colors.evvmGreen}▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬${colors.reset}`
    );
  }
  console.log();
}


/**
 * Displays a critical error message and exits the process
 *
 * Prints a formatted error message with GitHub issue link for support,
 * then terminates the CLI with exit code 1.
 *
 * @param {string} message - Error description to display
 * @returns {never} - Function never returns (process exits)
 */
export function criticalError(message: string) {
  console.error(`${colors.red}🯀 Critical Error ${message}${colors.reset}`);
  console.log(
    "Please try again. If the issue persists, create an issue on GitHub:"
  );
  console.log(
    `${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}`
  );

  process.exit(1);
}

/**
 * Displays a critical error with custom message and exits the process
 *
 * Similar to criticalError but allows an additional custom message
 * to be displayed before terminating the CLI.
 *
 * @param {string} message - Main error description
 * @param {string} extraMessage - Additional context or instructions
 * @returns {never} - Function never returns (process exits)
 */
export function criticalErrorCustom(message: string, extraMessage: string) {
  console.error(`${colors.red}🯀 Critical Error:${colors.reset} ${message}`);
  if (extraMessage) {
    console.log(`${extraMessage}`);
  }
  process.exit(1);
}

/**
 * Displays a non-fatal error message
 *
 * Prints a formatted error message without terminating the CLI process,
 * allowing recovery or continuation with user intervention.
 *
 * @param {string} message - Error description
 * @param {string} [extraMessage=""] - Optional additional context
 * @returns {void}
 */
export function error(message: string, extraMessage: string = "") {
  console.error(`${colors.red}🯀 Error:${colors.reset} ${message}`);
  if (extraMessage) {
    console.log(`${extraMessage}`);
  }
}

/**
 * Displays a non-fatal error message and exits the process
 *
 * Prints a formatted error message and then terminates the CLI process
 * with exit code 1.
 *
 * @param {string} message - Error description
 * @param {string} [extraMessage=""] - Optional additional context
 * @returns {never} - Function never returns (process exits)
 */
export function customErrorWithExit(
  message: string,
  extraMessage: string = ""
) {
  console.error(`${colors.red}🯀 ${message}${colors.reset}`);
  if (extraMessage) {
    console.log(`${extraMessage}`);
  }
  process.exit(1);
}

/**
 * Displays a warning message
 *
 * Prints a formatted warning message to indicate potential issues
 * or important information that doesn't require termination.
 *
 * @param {string} message - Warning description
 * @param {string} [extraMessage=""] - Optional additional context
 * @returns {void}
 */
export function warning(message: string, extraMessage: string = "") {
  console.warn(`${colors.yellow}⚠ Warning:${colors.reset} ${message}`);
  if (extraMessage) {
    console.log(`${extraMessage}`);
  }
}

/**
 * Displays a success confirmation message
 *
 * Prints a formatted confirmation message with a checkmark symbol
 * to indicate successful completion of an operation.
 *
 * @param {string} message - Confirmation message to display
 * @returns {void}
 */
export function confirmation(message: string) {
  console.log(`${colors.evvmGreen}✓${colors.reset}  ${message}`);
}

/**
 * Displays a warning about cross-chain protocol unavailability
 *
 * Prints a formatted warning when a specific cross-chain protocol
 * (Hyperlane, LayerZero, or Axelar) is not available on a target chain.
 * Optionally includes a URL for checking protocol availability.
 *
 * @param {string} chainName - Name of the blockchain network
 * @param {number} chainId - Chain ID of the network
 * @param {string} [crossChainProtocol="Cross-chain protocol"] - Name of the protocol
 * @param {string} [url=""] - Optional URL for availability information
 * @returns {void}
 */
export function warningCrossChainSuportNotAvailable(
  chainName: string,
  chainId: number,
  crossChainProtocol: string = "Cross-chain protocol",
  url: string = ""
) {
  console.log(
    `\n${colors.yellow}⚠ Warning:${colors.reset} ${crossChainProtocol} support not available on ${chainName} ${colors.darkGray}(${chainId})${colors.reset}`
  );
  if (url !== "") {
    console.log(`  ${colors.darkGray}Check availability at:${colors.reset}`);
    console.log(`  ${colors.darkGray}→ ${colors.blue}${url}${colors.reset}\n`);
  }
}

/**
 * Displays an informational message with blockchain network details
 *
 * Prints a formatted informational message that includes both the human-readable
 * chain name and numeric chain ID. If chain name is not available, displays only
 * the chain ID. Useful for contextual messages during deployment or operations.
 *
 * @param {string} message - Informational message to display
 * @param {string} chainName - Human-readable blockchain network name (e.g., "Sepolia")
 * @param {number} chainId - Numeric chain identifier
 * @returns {void}
 *
 * @example
 * ```typescript
 * infoWithChainData("Deploying", "Sepolia", 11155111);
 * // Output: "Deploying on Sepolia (11155111)"
 *
 * infoWithChainData("Deploying", "", 280919610);
 * // Output: "Deploying on Chain ID 280919610"
 * ```
 */
export function infoWithChainData(
  message: string,
  chainName: string,
  chainId: number
) {
  console.log(
    chainName
      ? `${colors.blue}${message} on ${chainName} ${colors.darkGray}(${chainId})${colors.reset}`
      : `${colors.blue}${message} on Chain ID ${chainId}${colors.reset}`
  );
}

/**
 * Displays a chain ID not supported error and exits
 *
 * Shows a detailed error message when attempting to deploy on an unsupported
 * chain ID, including guidance for:
 * - Testnet chains: Request support via GitHub issue
 * - Mainnet chains: EVVM mainnet limitations warning
 * - Local blockchains: Use alternative unregistered chain IDs
 *
 * Terminates the CLI with exit code 406 (Not Acceptable).
 *
 * @param {number} chainId - Unsupported chain ID
 * @returns {never} - Function never returns (process exits)
 */
export function chainIdNotSupported(chainId: number) {
  console.error(
    `${colors.red}Host Chain ID ${chainId} is not supported.,${colors.reset}`
  );
  console.log(
    `\n${colors.yellow}Possible solutions:${colors.reset}
    ${colors.bright}• Testnet chains:${colors.reset}
    Request support by creating an issue at:
    ${colors.blue}https://github.com/EVVM-org/evvm-registry-contracts${colors.reset}
    
    ${colors.bright}• Mainnet chains:${colors.reset}
    EVVM currently does not support mainnet deployments, do it manually at you own risk.
    
    ${colors.bright}• Local blockchains (Anvil/Hardhat):${colors.reset}
    Use an unregistered chain ID.
    ${colors.darkGray}Example: Chain ID 31337 is registered, use 1337 instead.${colors.reset}`
  );
  process.exit(406);
}

/**
 * Displays the EVVM ASCII logo
 *
 * Prints the EVVM branded ASCII art logo in green color
 * to the console as a banner for CLI startup or major operations.
 *
 * @returns {void}
 */
export function showEvvmLogo() {
  console.log(`${colors.evvmGreen}
░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
🮋 Version 3.0.0 "Ichiban" 🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋🮋
${colors.reset}`);
}

/**
 * Displays a formatted summary of base configuration settings
 *
 * Prints a comprehensive overview of:
 * - All configured contract addresses (Admin, Validator, Router, etc.)
 * - EVVM metadata (name, symbol, swap fee, decimals, etc.)
 *
 * Uses formatted table-like output with colored labels for readability.
 *
 * @param {BaseInputAddresses} addresses - Contract addresses configuration
 * @param {EvvmMetadata} evvmMetadata - EVVM token and protocol metadata
 * @returns {void}
 */
export function baseConfigurationSummary(
  addresses: BaseInputAddresses,
  evvmMetadata: EvvmMetadata
) {
  sectionSubtitle("Configuration Summary");
  console.log(`${colors.bright}Addresses:${colors.reset}`);
  for (const key of Object.keys(addresses) as (keyof BaseInputAddresses)[]) {
    console.log(`  ${colors.blue}${key}:${colors.reset} ${addresses[key]}`);
  }

  console.log(`\n${colors.bright}EVVM Metadata:${colors.reset}`);
  for (const [metaKey, metaValue] of Object.entries(evvmMetadata)) {
    if (metaKey === "EvvmID") continue;

    let displayValue = metaValue;
    if (typeof metaValue === "number" && metaValue > 1e15) {
      displayValue = metaValue.toLocaleString("fullwide", {
        useGrouping: false,
      });
    }
    console.log(`  ${colors.blue}${metaKey}:${colors.reset} ${displayValue}`);
  }
  console.log();
}

/**
 * Displays a formatted summary of cross-chain configuration settings
 *
 * Prints a comprehensive overview of cross-chain protocol configurations for:
 * - External chain admin address
 * - Host Chain Station: Hyperlane, LayerZero, and Axelar settings
 * - External Chain Station: Hyperlane, LayerZero, and Axelar settings
 *
 * Includes domain IDs, endpoint addresses, chain names, and gateway configurations
 * for all supported cross-chain messaging protocols.
 *
 * @param {ChainData} externalChainData - Metadata for external blockchain
 * @param {ChainData} hostChainData - Metadata for host blockchain
 * @param {CrossChainInputs} crossChainInputs - Cross-chain protocol configurations
 * @returns {void}
 */
export function crossChainConfigurationSummary(
  externalChainData: ChainData,
  hostChainData: ChainData,
  crossChainInputs: CrossChainInputs
) {
  sectionSubtitle("Cross-Chain Configuration Summary");
  console.log(`
${colors.bright}External Admin:${colors.reset}
  ${colors.blue}${crossChainInputs.adminExternal}${colors.reset}

${colors.bright}Host Chain Station (${hostChainData.Chain}):${colors.reset}
  ${colors.darkGray}→${colors.reset} Hyperlane External Domain ID: ${colors.blue}${crossChainInputs.crosschainConfigHost.hyperlane.externalChainStationDomainId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Hyperlane Mailbox: ${colors.blue}${crossChainInputs.crosschainConfigHost.hyperlane.mailboxAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} LayerZero External EId: ${colors.blue}${crossChainInputs.crosschainConfigHost.layerZero.externalChainStationEid}${colors.reset}
  ${colors.darkGray}→${colors.reset} LayerZero Endpoint: ${colors.blue}${crossChainInputs.crosschainConfigHost.layerZero.endpointAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar External Chain: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.externalChainStationChainName}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar Gateway: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.gatewayAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar Gas Service: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.gasServiceAddress}${colors.reset}

${colors.bright}External Chain Station (${externalChainData.Chain}):${colors.reset}
  ${colors.darkGray}→${colors.reset} Hyperlane Host Domain ID: ${colors.blue}${crossChainInputs.crosschainConfigExternal.hyperlane.hostChainStationDomainId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Hyperlane Mailbox: ${colors.blue}${crossChainInputs.crosschainConfigExternal.hyperlane.mailboxAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} LayerZero Host EId: ${colors.blue}${crossChainInputs.crosschainConfigExternal.layerZero.hostChainStationEid}${colors.reset}
  ${colors.darkGray}→${colors.reset} LayerZero Endpoint: ${colors.blue}${crossChainInputs.crosschainConfigExternal.layerZero.endpointAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar Host Chain: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.hostChainStationChainName}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar Gateway: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.gatewayAddress}${colors.reset}
  ${colors.darkGray}→${colors.reset} Axelar Gas Service: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.gasServiceAddress}${colors.reset}
`);
}

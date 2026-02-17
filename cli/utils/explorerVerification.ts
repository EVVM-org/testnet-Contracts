/**
 * Explorer Verification Utilities
 *
 * Handles block explorer verification configuration for deployed contracts.
 * Supports multiple verification providers including Etherscan, Blockscout, and Sourcify.
 *
 * @module cli/utils/explorerVerification
 */

import { promptSecret, promptSelect, promptString } from "./prompts";

/**
 * Prompts user to select and configure block explorer verification
 *
 * Provides options for various verification methods:
 * - Etherscan v2: Requires API key
 * - Blockscout: Requires homepage URL
 * - Sourcify: Uses public Sourcify server
 * - Custom: Allows custom verification flags
 * - Skip: Proceeds without verification (not recommended)
 *
 * @returns {Promise<string | undefined>} Verification flags for forge script, or undefined if setup fails
 */
export async function explorerVerification(
  prompt = "Select block explorer verification:"
): Promise<string | undefined> {
  const verification = await promptSelect(prompt, [
    "Etherscan v2",
    "Blockscout",
    "Sourcify",
    "Custom",
    "Skip verification (not recommended)",
  ]);

  let verificationflag: string = "";

  switch (verification) {
    case "Etherscan v2":
      let etherscanAPI = process.env.ETHERSCAN_API
        ? process.env.ETHERSCAN_API
        : await promptSecret("Enter your Etherscan API key");

      verificationflag = `--verify --etherscan-api-key ${etherscanAPI}`;
      break;

    case "Blockscout":
      let blockscoutHomepage = process.env.BLOCKSCOUT_HOMEPAGE
        ? process.env.BLOCKSCOUT_HOMEPAGE
        : await promptString("Enter your Blockscout homepage URL");
      verificationflag = `--verify --verifier blockscout --verifier-url ${blockscoutHomepage}/api/`;
      break;
    case "Sourcify":
      verificationflag = `--verify --verifier sourcify --verifier-url https://sourcify.dev/server`;
      break;
    case "Custom":
      verificationflag = await promptString("Enter your custom verification flags:");
      break;
    case "Skip verification (not recommended)":
      verificationflag = "";
      break;
  }
  return verificationflag;
}

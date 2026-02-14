/**
 * User Input Prompt Utilities
 *
 * Provides interactive prompting functions for gathering user input with validation.
 * Supports various input types including strings, numbers, addresses, and selections.
 *
 * @module cli/utils/prompts
 */

import { colors } from "../constants";
import { isAddress, getAddress } from "viem";

/**
 * Core input function with full cursor navigation support
 *
 * Provides a raw input handler that supports:
 * - Left/Right arrow keys for cursor movement
 * - Backspace and Delete for character removal
 * - Home/End keys for jumping to start/end
 *
 * @param {string} message - Prompt message to display
 * @param {Object} options - Configuration options
 * @param {boolean} [options.masked=false] - Whether to mask input with asterisks
 * @param {string} [options.defaultValue] - Default value if user provides no input
 * @returns {Promise<string>} The user's input
 */
export function promptInput(
  message: string,
  options: { masked?: boolean; defaultValue?: string } = {}
): Promise<string> {
  const { masked = false, defaultValue } = options;
  process.stdout.write(`${message} `);

  let input = "";
  let cursorPos = 0;

  const renderInput = () => {
    // Move cursor to start of input area
    process.stdout.write(`\r\x1b[K`);
    process.stdout.write(`${message} `);
    // Display input (masked or normal)
    const displayText = masked ? "*".repeat(input.length) : input;
    process.stdout.write(displayText);
    // Move cursor to correct position
    const moveBack = input.length - cursorPos;
    if (moveBack > 0) {
      process.stdout.write(`\x1b[${moveBack}D`);
    }
  };

  if (process.stdin.isTTY) process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding("utf8");

  return new Promise<string>((resolve) => {
    const onKeyPress = (key: string) => {
      // Ctrl+C - exit
      if (key === "\u0003") {
        if (process.stdin.isTTY) process.stdin.setRawMode(false);
        process.stdin.pause();
        process.exit();
      }

      // Enter - submit
      if (key === "\r" || key === "\n") {
        process.stdin.removeListener("data", onKeyPress);
        if (process.stdin.isTTY) process.stdin.setRawMode(false);
        process.stdin.pause();
        console.log();
        // Return default if empty and default exists
        if (!input && defaultValue !== undefined) {
          resolve(defaultValue);
        } else {
          resolve(input);
        }
        return;
      }

      // Backspace
      if (key === "\x7f" || key === "\b") {
        if (cursorPos > 0) {
          input = input.slice(0, cursorPos - 1) + input.slice(cursorPos);
          cursorPos--;
          renderInput();
        }
        return;
      }

      // Delete key (escape sequence)
      if (key === "\x1b[3~") {
        if (cursorPos < input.length) {
          input = input.slice(0, cursorPos) + input.slice(cursorPos + 1);
          renderInput();
        }
        return;
      }

      // Left arrow
      if (key === "\x1b[D") {
        if (cursorPos > 0) {
          cursorPos--;
          process.stdout.write("\x1b[D");
        }
        return;
      }

      // Right arrow
      if (key === "\x1b[C") {
        if (cursorPos < input.length) {
          cursorPos++;
          process.stdout.write("\x1b[C");
        }
        return;
      }

      // Home key
      if (key === "\x1b[H" || key === "\x1b[1~") {
        if (cursorPos > 0) {
          process.stdout.write(`\x1b[${cursorPos}D`);
          cursorPos = 0;
        }
        return;
      }

      // End key
      if (key === "\x1b[F" || key === "\x1b[4~") {
        if (cursorPos < input.length) {
          process.stdout.write(`\x1b[${input.length - cursorPos}C`);
          cursorPos = input.length;
        }
        return;
      }

      // Ignore other escape sequences (up/down arrows, etc.)
      if (key.startsWith("\x1b")) {
        return;
      }

      // Handle pasted text or regular character input
      // Filter out control characters
      const printableChars = key.replace(/[\x00-\x1f]/g, "");
      if (printableChars.length > 0) {
        input = input.slice(0, cursorPos) + printableChars + input.slice(cursorPos);
        cursorPos += printableChars.length;
        renderInput();
      }
    };

    process.stdin.on("data", onKeyPress);
  });
}

/**
 * Prompts user for string input with optional default value
 *
 * Supports full cursor navigation with arrow keys.
 *
 * @param {string} message - Prompt message to display
 * @param {string} [defaultValue] - Default value if user provides no input
 * @returns {Promise<string>} User's input or default value
 */
export async function promptString(message: string, defaultValue?: string): Promise<string> {
  const input = await promptInput(message, { defaultValue });

  if (!input && defaultValue !== undefined) return defaultValue;

  if (!input) {
    console.log(
      `${colors.red}Input cannot be empty. Please enter a value.${colors.reset}`
    );
    return promptString(message, defaultValue);
  }

  return input;
}

/**
 * Prompts user for numeric input with validation
 *
 * Validates that input is a valid positive number and recursively re-prompts on invalid input.
 * Supports full cursor navigation with arrow keys.
 *
 * @param {string} message - Prompt message to display
 * @param {number} [defaultValue] - Default value if user provides no input
 * @returns {Promise<number>} Valid positive number
 */
export async function promptNumber(message: string, defaultValue?: number): Promise<number> {
  const input = await promptInput(message, { defaultValue: defaultValue?.toString() });

  if (!input && defaultValue !== undefined) return defaultValue;

  const num = Number(input);
  if (isNaN(num) || num < 0) {
    console.log(
      `${colors.red}Invalid number. Please enter a valid positive number.${colors.reset}`
    );
    return promptNumber(message, defaultValue);
  }

  return num;
}

/**
 * Prompts user for Ethereum address with format validation
 *
 * Validates address format (0x followed by 40 hex characters) and recursively
 * re-prompts on invalid input.
 * Supports full cursor navigation with arrow keys.
 *
 * @param {string} message - Prompt message to display
 * @param {`0x${string}`} [defaultValue] - Default address if user provides no input
 * @returns {Promise<`0x${string}`>} Valid Ethereum address
 */
export async function promptAddress(
  message: string,
  defaultValue?: `0x${string}`
): Promise<`0x${string}`> {
  const input = await promptInput(message, { defaultValue });

  if (!input && defaultValue !== undefined) return getAddress(defaultValue);

  if (!isAddress(input || "")) {
    console.log(
      `${colors.red}Invalid address format. Please enter a valid Ethereum address.${colors.reset}`
    );
    return promptAddress(message, defaultValue);
  }

  return getAddress(input as `0x${string}`);
}

/**
 * Prompts user for yes/no confirmation
 *
 * Accepts 'y' or 'n' input (case-insensitive) and validates the response.
 * Supports full cursor navigation with arrow keys.
 *
 * @param {string} message - Prompt message to display
 * @param {string} [defaultValue] - Default value if user provides no input
 * @returns {Promise<boolean>} True for 'y', False for 'n'
 */
export async function promptYesNo(message: string, defaultValue?: string): Promise<boolean> {
  const input = await promptInput(message, { defaultValue });
  const val = (input ?? defaultValue)?.trim().toLowerCase();

  if (!val || (val !== "y" && val !== "n")) {
    if (!input && defaultValue !== undefined) return defaultValue.toLowerCase() === "y";
    console.log(`${colors.red}Please enter 'y' or 'n'${colors.reset}`);
    return promptYesNo(message, defaultValue);
  }

  return val === "y";
}

/**
 * Prompts user for secret input with masked display
 *
 * Displays asterisks instead of actual characters while user types.
 * Supports full cursor navigation with arrow keys.
 *
 * @param {string} message - Prompt message to display
 * @returns {Promise<string>} The secret input provided by user
 */
export function promptSecret(message: string): Promise<string> {
  return promptInput(message, { masked: true });
}

/**
 * Prompts user to select from a list of options using arrow keys
 *
 * Provides an interactive menu where users can navigate with arrow keys
 * and select with Enter. Selected option is highlighted.
 *
 * @param {string} message - Prompt message to display above options
 * @param {string[]} options - Array of options to choose from
 * @returns {Promise<string>} The selected option
 */
export async function promptSelect(
  message: string,
  options: string[]
): Promise<string> {
  console.log(`\n${colors.yellow}${message}${colors.reset}`);

  let selectedIndex = 0;
  let isFirstRender = true;

  const renderOptions = () => {
    if (!isFirstRender) process.stdout.write(`\x1b[${options.length}A`);

    isFirstRender = false;

    options.forEach((option, index) => {
      process.stdout.write("\x1b[2K");
      if (index === selectedIndex) {
        console.log(`${colors.evvmGreen}🭬 ${option}${colors.reset}`);
      } else {
        console.log(`  ${option}`);
      }
    });
  };

  renderOptions();

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
  }
  process.stdin.resume();
  process.stdin.setEncoding("utf8");

  return new Promise<string>((resolve) => {
    const onKeyPress = (key: string) => {
      if (key === "\u0003") {
        if (process.stdin.isTTY) {
          process.stdin.setRawMode(false);
        }
        process.stdin.pause();
        process.exit();
      }

      if (key === "\x1b[A") {
        selectedIndex =
          selectedIndex > 0 ? selectedIndex - 1 : options.length - 1;
        renderOptions();
      }

      if (key === "\x1b[B") {
        selectedIndex =
          selectedIndex < options.length - 1 ? selectedIndex + 1 : 0;
        renderOptions();
      }

      if (key === "\r" || key === "\n") {
        process.stdin.removeListener("data", onKeyPress);
        if (process.stdin.isTTY) {
          process.stdin.setRawMode(false);
        }
        process.stdin.pause();

        const selected = options[selectedIndex];
        if (selected) {
          console.log();
          resolve(selected);
        }
      }
    };

    process.stdin.on("data", onKeyPress);
  });
}

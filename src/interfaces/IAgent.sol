// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

/// @title IAgent
/// @notice Interface for the recovery agent used in secure account recovery for smart contract
/// wallets.
///         The recovery agent provides initialization and signature validation functionalities.
interface IAgent {
    /// @notice Initializes the recovery agent with the given parameters.
    /// @dev This function is called after deployment to configure the agent with specific
    /// initialization data.
    /// @param data Arbitrary initialization data used to set up the agent.
    function initialize(bytes calldata data) external;

    /// @notice Validates a signature for a given digest to ensure it matches the expected format.
    /// @dev This function adheres to the EIP-1271 standard for validating contract signatures.
    /// @param digest The hash of the data that is being verified.
    /// @param signature The signature to validate against the digest.
    /// @return selector The EIP-1271 magic value (0x1626ba7e) if the signature is valid, otherwise
    /// it reverts.
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4 selector);
}

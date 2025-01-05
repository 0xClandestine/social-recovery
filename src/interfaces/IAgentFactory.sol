// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

/// @title IAgentFactory
/// @notice This contract facilitates the deployment of counterfactual recovery agents, which are
/// used for secure account recovery in smart contract wallets. These recovery agents are deployed
/// using the `CREATE2` opcode (EIP-1014), enabling their addresses to be precomputed prior to
/// deployment. The term "counterfactual" refers to the ability to precompute the agent's address
/// before its deployment. This is leveraged to ensure that attackers have no knowledge of any
/// potential attack surface, as the agent would initially appear as an externally owned account. The
/// attack surface only becomes visible once the agent is deployed, at which point it is already too
/// late for any intervention.
///
/// The deployment process consists of the following steps:
/// 1. Users precompute the recovery agent's address and assign it specific privileges for their
///     smart contract wallet.
/// 2. When needed, user then `commits` a hash of the agent's deployment parameters (e.g., revealer,
///     implementation address, salt, etc.).
/// 3. After committing, the user must wait for a predetermined time before calling `reveal` with
///     the unhashed parameters to finalize the deployment. Upon revelation, the agent transitions
///     from a counterfactual address (appearing as an externally owned account) to an active smart
///     contract.
/// 4. The recovery agent then uses the granted privileges to facilitate account recovery.
interface IAgentFactory {
    /// @dev Error thrown when the specified commitment does not exist.
    error NonexistentCommitment();
    /// @dev Error thrown when a commitment is not yet eligible for deployment.
    error CommitmentNotReady();

    /// @notice Emitted when a new commitment to deploy a recovery agent is successfully created.
    /// @param commitment The unique hash representing the commitment to deploy the agent.
    event Commit(bytes32 indexed commitment);

    /// @notice Emitted when an agent is deployed, transitioning from a counterfactual state to an
    /// active smart contract.
    /// @param commitment The unique hash representing the commitment to deploy the agent.
    /// @param agent The address of the deployed recovery agent contract.
    event Reveal(bytes32 indexed commitment, address agent);

    /// @notice Creates a commitment to deploy a recovery agent in the future.
    /// @param commitment The unique hash representing the commitment to deploy the agent.
    function commit(bytes32 commitment) external;

    /// @notice Deploys a counterfactual recovery agent using the `CREATE2` opcode, based on the
    /// parameters defined in a pre-existing commitment.
    /// @dev Deployment finalizes the agent, transitioning it from a non-existent but predictable
    /// state to an active smart contract. The `CREATE2` opcode guarantees a deterministic address
    /// based on the provided parameters. The agent remains hidden until revealed, reducing the risk
    /// of preemptive detection or exploitation.
    /// @param implementation The address of the implementation contract to which the deployed agent
    /// will delegate calls.
    /// @param salt A unique `bytes32` value to ensure a deterministic and unique agent address.
    /// @param data Initialization data to configure the agent upon deployment.
    /// @return agent The address of the deployed recovery agent.
    function reveal(address implementation, bytes32 salt, bytes calldata data)
        external
        returns (address agent);

    /// @notice Returns the timestamp when a specific commitment was created.
    /// @dev This function enforces delays before deployment, adding a layer of security by
    /// preventing immediate exploitation of freshly created commitments.
    /// @param commitment The unique hash representing the commitment to deploy the agent.
    /// @return The Unix timestamp (in seconds) of when the commitment was created.
    function commitTime(bytes32 commitment) external view returns (uint256);
}

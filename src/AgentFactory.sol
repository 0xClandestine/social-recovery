// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { LibClone } from "solady/utils/LibClone.sol";

import { IAgent } from "src/interfaces/IAgent.sol";
import { IAgentFactory } from "src/interfaces/IAgentFactory.sol";

contract AgentFactory is IAgentFactory {
    /// @inheritdoc IAgentFactory
    mapping(bytes32 commitment => uint256 time) public commitTime;

    /// @inheritdoc IAgentFactory
    function commit(bytes32 commitment) external virtual {
        commitTime[commitment] = block.timestamp;
        emit Commit(commitment);
    }

    /// @inheritdoc IAgentFactory
    function reveal(address implementation, bytes32 salt, bytes calldata data)
        external
        virtual
        returns (address agent)
    {
        // Reconstruct the commitment hash from the provided parameters.
        bytes32 commitment = keccak256(abi.encodePacked(msg.sender, implementation, salt));
        // Fetch the timestamp of the commitment to verify its existence and readiness.
        uint256 commitmentTime = commitTime[commitment];

        // Revert if no commitment exists for the given parameters.
        if (commitmentTime == 0) revert NonexistentCommitment();
        // Revert if the commitment waiting period not yet satisfied.
        if (commitmentTime + 1 hours > block.timestamp) revert CommitmentNotReady();

        // Use `CREATE2` to deterministically deploy the agent at its counterfactual address.
        agent = LibClone.cloneDeterministic(implementation, salt);
        // Initialize the deployed agent with the provided data.
        IAgent(agent).initialize(data);
        // Emit an event to signal that the agent has been successfully deployed.
        emit Reveal(commitment, agent);
    }
}

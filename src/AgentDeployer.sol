// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "social-recovery/interfaces/IAgent.sol";
import "social-recovery/interfaces/IAgentDeployer.sol";
import "solady/utils/LibClone.sol";

contract AgentDeployer is IAgentDeployer {
    /// @inheritdoc IAgentDeployer
    mapping(bytes32 commitment => uint256 time) public commitTime;

    /// @inheritdoc IAgentDeployer
    function commit(bytes32 commitment) external virtual {
        commitTime[commitment] = block.timestamp;
        emit Commit(commitment);
    }

    /// @inheritdoc IAgentDeployer
    function reveal(address implementation, bytes32 salt, bytes calldata data)
        public
        virtual
        returns (address agent)
    {
        // Reconstruct the commitment hash from the provided parameters.
        bytes32 commitment = keccak256(abi.encodePacked(msg.sender, implementation, salt));

        // Fetch the timestamp of the commitment to verify its existence and readiness.
        uint256 commitmentTime = commitTime[commitment];

        // Revert if no commitment exists for the given parameters.
        if (commitmentTime == 0) revert NonexistentCommitment();

        // QUESTION: How long should we wait? Does waiting guarantee a front-run-free deployment?
        // Revert if the commitment was made in the same block (waiting period not yet satisfied).
        if (commitmentTime == block.timestamp) revert CommitmentNotReady();

        // Use `CREATE2` to deterministically deploy the agent at its counterfactual address.
        agent = LibClone.cloneDeterministic(implementation, salt);

        // Initialize the deployed agent with the provided data.
        IAgent(agent).initialize(data);

        // Emit an event to signal that the agent has been successfully deployed.
        emit Reveal(commitment, agent);
    }
}

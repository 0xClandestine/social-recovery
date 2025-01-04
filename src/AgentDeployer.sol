// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "social-recovery/interfaces/IAgent.sol";
import "social-recovery/interfaces/IAgentDeployer.sol";
import "solady/utils/LibClone.sol";

contract AgentDeployer is IAgentDeployer {
    mapping(bytes32 commitment => uint256 time) public commitTime;

    function commit(bytes32 commitment) external virtual {
        commitTime[commitment] = block.timestamp;
        emit Commit(commitment);
    }

    function reveal(address implementation, bytes32 salt, bytes calldata data)
        public
        virtual
        returns (address agent)
    {
        bytes32 commitment =
            keccak256(abi.encodePacked(msg.sender, implementation, salt));
        uint256 commitmentTime = commitTime[commitment];

        if (commitmentTime == 0) revert NonexistentCommitment();
        // QUESTION: How long should we wait? Does waiting garuntee a front-run
        // free deployment?
        if (commitmentTime == block.timestamp) revert CommitmentNotReady();

        agent = LibClone.cloneDeterministic(implementation, salt);
        
        IAgent(agent).initialize(data);

        emit Reveal(commitment, agent);
    }
}

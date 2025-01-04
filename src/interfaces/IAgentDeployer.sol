// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

interface IAgentDeployer {
    error NonexistentCommitment();
    error CommitmentNotReady();

    event Commit(bytes32 indexed commitment);
    event Reveal(bytes32 indexed commitment, address agent);

    function commit(bytes32 commitment) external;
    function reveal(address implementation, bytes32 salt, bytes calldata data)
        external
        returns (address agent);

    function commitTime(bytes32 commitment) external view returns (uint256);
}

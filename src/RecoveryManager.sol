// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { LibClone } from "solady/utils/LibClone.sol";

contract RecoveryManager {
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(bytes32 => uint256)) public maturityOf;

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function commit(bytes32 commitment) external virtual {
        unchecked {
            maturityOf[msg.sender][commitment] = block.timestamp + 1 hours;
        }
    }

    function reveal(
        address agent,
        address account,
        bytes memory initializationArgs,
        bytes memory immutableArgs,
        bytes32 salt
    ) external virtual returns (address instance) {
        bytes32 commitment = keccak256(
            abi.encodePacked(
                agent, account, initializationArgs, immutableArgs, salt
            )
        );
        uint256 maturity = maturityOf[msg.sender][commitment];

        if (maturity > block.timestamp) revert();
        if (maturity == 0) revert();

        instance = LibClone.cloneDeterministic(agent, immutableArgs, salt);

        RecoveryAgent(instance).initialize(initializationArgs);
    }

    /// -----------------------------------------------------------------------
    /// Read-only Helpers
    /// -----------------------------------------------------------------------

    function computeAgentAddress(
        address agent,
        bytes memory immutableArgs,
        bytes32 salt
    ) external view virtual returns (address) {
        return LibClone.predictDeterministicAddress(
            agent, immutableArgs, salt, address(this)
        );
    }

    function computeCommitmentHash(
        address agent,
        address account,
        bytes memory initializationArgs,
        bytes memory immutableArgs,
        bytes32 salt
    ) external view virtual returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                agent, account, initializationArgs, immutableArgs, salt
            )
        );
    }
}

abstract contract RecoveryAgent {
    function initialize(bytes calldata initializationArgs) external virtual;
    function isValidSignature(bytes32 digest, bytes memory signature)
        external
        view
        virtual
        returns (bytes4);
}

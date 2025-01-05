// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Ownable } from "solady/auth/Ownable.sol";
import { Initializable } from "solady/utils/Initializable.sol";

import { IAgent } from "src/interfaces/IAgent.sol";

contract OwnableAgent is Ownable, Initializable, IAgent {
    mapping(bytes32 digest => bool valid) public isValidDigest;

    function validateDigest(bytes32 digest, bool valid) external onlyOwner {
        isValidDigest[digest] = valid;
    }

    /// @inheritdoc IAgent
    function initialize(bytes calldata data) external virtual override initializer {
        _initializeOwner(abi.decode(data, (address)));
    }

    /// @inheritdoc IAgent
    function isValidSignature(bytes32 digest, bytes memory)
        external
        view
        virtual
        override
        returns (bytes4 selector)
    {
        return isValidDigest[digest] ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }

    /// @dev Gnosis Safe compatible `isValidSignature` variant.
    function isValidSignature(bytes memory data, bytes memory)
        external
        view
        virtual
        returns (bytes4 selector)
    {
        return isValidDigest[keccak256(data)] ? bytes4(0x20c13b0b) : bytes4(0xffffffff);
    }
}

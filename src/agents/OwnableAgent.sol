// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "social-recovery/interfaces/IAgent.sol";
import "solady/auth/Ownable.sol";

contract OwnableAgent is Ownable, IAgent {
    mapping(bytes32 digest => bool valid) public isValidDigest;

    function initialize(bytes calldata data) external virtual override {
        _initializeOwner(abi.decode(data, (address)));
    }

    function validateDigest(bytes32 digest, bool valid) external onlyOwner {
        isValidDigest[digest] = valid;
    }

    function isValidSignature(bytes32 digest, bytes calldata)
        external
        view
        virtual
        override
        returns (bytes4 selector)
    {
        return isValidDigest[digest] ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }
}

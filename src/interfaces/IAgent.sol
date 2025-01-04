// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

interface IAgent {
    function initialize(bytes calldata data) external;
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4 selector);
}

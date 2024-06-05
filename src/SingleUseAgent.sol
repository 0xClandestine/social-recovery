// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Initializable } from "solady/utils/Initializable.sol";
import { Clone } from "solady/utils/Clone.sol";

import { RecoveryAgent } from "./RecoveryManager.sol";

/// @notice Simple recovery agent that can provide a single valid signature
/// after some predetermined time has elapsed.
contract SingleUseAgent is Initializable, RecoveryAgent, Clone {
    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    function expectedAccount() external view virtual returns (address) {
        return _getArgAddress(0x00);
    }

    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    /// NOTE: These parameters are stored despite being constant values. This is
    /// to ensure that they do not affect the deterministic address of this
    /// contract.

    function expectedDigest() external view virtual returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            digest := sload(address())
        }
    }

    function timelockMaturity()
        external
        view
        virtual
        returns (uint256 maturity)
    {
        /// @solidity memory-safe-assembly
        assembly {
            maturity := sload(codesize())
        }
    }

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    function initialize(bytes calldata /* initializationArgs */ )
        external
        virtual
        override(RecoveryAgent)
        initializer
    {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(address(), calldataload(68))
            sstore(codesize(), add(timestamp(), calldataload(100)))
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC-1271 Signature Validation
    /// -----------------------------------------------------------------------

    uint256 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    function isValidSignature(bytes32 digest, bytes memory)
        external
        view
        virtual
        override(RecoveryAgent)
        returns (bytes4 selector)
    {
        address _expectedAccount = _getArgAddress(0x00);
        /// @solidity memory-safe-assembly
        assembly {
            selector := shl(224, 0xFFFFFFFF)
            if eq(caller(), _expectedAccount) {
                if eq(digest, sload(address())) {
                    if gt(timestamp(), sload(codesize())) {
                        selector := shl(224, ERC1271_MAGIC_VALUE)
                    }
                }
            }
        }
    }
}

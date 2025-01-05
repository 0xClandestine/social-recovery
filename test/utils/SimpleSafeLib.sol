// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "safe-smart-account/Safe.sol";

library SimpleSafeLib {
    function setup(Safe safe, address[] memory owners, uint256 threshold) internal returns (Safe) {
        safe.setup({
            _owners: owners,
            _threshold: threshold,
            to: address(0),
            data: "",
            fallbackHandler: address(0),
            paymentToken: address(0),
            payment: 0,
            paymentReceiver: payable(address(0))
        });
        return safe;
    }

    function executeCall(
        Safe safe,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) internal returns (Safe) {
        require(
            safe.execTransaction({
                to: to,
                value: value,
                data: data,
                operation: Enum.Operation.Call,
                safeTxGas: 30_000_000,
                baseGas: 0,
                gasPrice: 0,
                gasToken: address(0),
                refundReceiver: payable(address(0)),
                signatures: signatures
            }),
            "Gnosis Safe: failed to execute transaction"
        );
        return safe;
    }

    function getContractSignature(Safe, address agent) internal pure returns (bytes memory) {
        return abi.encodePacked(
            bytes32(uint256(uint160(address(agent)))), bytes32(uint256(65)), uint8(0), bytes32(0)
        );
    }

    function getSignableData(Safe safe, address to, uint256 value, bytes memory data, uint256 nonce)
        internal
        view
        returns (bytes memory)
    {
        return safe.encodeTransactionData({
            to: to,
            value: value,
            data: data,
            operation: Enum.Operation.Call,
            safeTxGas: 30_000_000,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            _nonce: nonce
        });
    }
}

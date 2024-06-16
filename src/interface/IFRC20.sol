// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFRC20 {
    function setFIDOnly(bool _value) external;

    function setFIDWhitelist(address _address, bool _allowed) external;

    function getFID(address owner) external view returns (uint256);
}

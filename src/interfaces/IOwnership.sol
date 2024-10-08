// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOwnership {
    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);
}

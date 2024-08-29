// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    //requires unanimous vote to change the address of the majority multisig address
    function transferMajorityApproval(address _newMajorityApprover) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setMajorityApprover(_newMajorityApprover);
    }

    function majorityApprover()
        external
        view
        returns (address majorityApprover_)
    {
        majorityApprover_ = LibDiamond.majorityApprover();
    }
}

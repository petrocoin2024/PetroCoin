// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TokenTimelock} from "../utils/TokenTimelock.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibVaultFactory} from "../libraries/LibVaultFactory.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract VaultFactoryFacet {
    function vaultCount() public view returns (uint256) {
        return LibVaultFactory._getVaultCount();
    }

    function getHolderVaults(
        address holder
    ) public view returns (uint256[] memory) {
        return LibVaultFactory._getHolderVaults(holder);
    }

    function getVaultLocationById(
        uint256 vaultId
    ) public view returns (address) {
        return LibVaultFactory._getVaultLocationById(vaultId);
    }

    function getVaultReleaseTime(
        uint256 vaultId
    ) public view returns (uint256) {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.releaseTime();
    }

    function getVaultBalanceById(
        uint256 vaultId
    ) public view returns (uint256) {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.token().balanceOf(address(timelock));
    }

    function getVaultInitialBeneficiary(
        uint256 vaultId
    ) public view returns (address) {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.initialBeneficiary();
    }

    function getVaultFractionalOwnerBalance(
        uint256 vaultId,
        address fractionalOwner
    ) public view returns (uint256 balance) {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        balance = timelock.balanceOf(fractionalOwner);
    }

    function isVaultDestroyed(uint256 vaultId) public view returns (bool) {
        return LibVaultFactory._isVaultDestroyed(vaultId);
    }

    function releaseVaultTokens(
        uint256 vaultId
    ) public returns (uint256 remainingSupply) {
        // A destroyed vault holds no tokens, so release would fail anyway when
        // the timelock tried to pay out. Reject it here to say why.
        require(
            !LibVaultFactory._isVaultDestroyed(vaultId),
            "VaultFactoryFacet: vault has been destroyed"
        );
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        require(
            timelock.balanceOf(msg.sender) > 0 ||
                msg.sender == LibDiamond.contractOwner(),
            "VaultFactoryFacet: only beneficiary or owner can release vault tokens"
        );
        remainingSupply = timelock.release(msg.sender);
    }
}

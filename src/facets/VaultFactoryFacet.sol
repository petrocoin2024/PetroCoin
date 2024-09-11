// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TokenTimelock} from "../utils/TokenTimelock.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibVaultFactory} from "../libraries/LibVaultFactory.sol";

contract VaultFactoryFacet {
    //todo test as an internal function only
    function createTokenTimelock(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime
    ) public returns (TokenTimelock) {
        return _createTokenTimelock(token, beneficiary, releaseTime);
    }

    function _createTokenTimelock(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime
    ) internal returns (TokenTimelock) {
        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[beneficiary].push(vaultId);

        TokenTimelock timelock = new TokenTimelock(
            token,
            beneficiary,
            releaseTime
        );
        es.vaultLocation[vaultId] = address(timelock);

        return timelock;
    }

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

    function getVaultBeneficiary(
        uint256 vaultId
    ) public view returns (address) {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.beneficiary();
    }

    function releaseVaultTokens(uint256 vaultId) public {
        TokenTimelock timelock = TokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        timelock.release();
    }
}

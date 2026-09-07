pragma solidity ^0.8.26;

library LibVaultFactory {
    bytes32 constant VAULT_FACTORY_STORAGE_POSITION =
        keccak256("petrocoin.diamond.VaultFactory.storage");

    struct VaultFactoryStorage {
        //total number of vaults created
        uint256 vaultCount;
        //mapping from each wallet address to the vaultIDs that were created for it
        mapping(address => uint256[]) holderVaults;
        //mapping from each vaultID to the address where it is located
        mapping(uint256 => address) vaultLocation;
        //vaults whose tokens have been burned and which no longer count as open
        //appended to the end of the struct so existing slots keep their layout
        mapping(uint256 => bool) vaultDestroyed;
    }

    function vaultFactoryStorage()
        internal
        pure
        returns (VaultFactoryStorage storage es)
    {
        bytes32 position = VAULT_FACTORY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function _getVaultLocationById(
        uint256 _vaultId
    ) internal view returns (address) {
        return vaultFactoryStorage().vaultLocation[_vaultId];
    }

    function _getVaultCount() internal view returns (uint256) {
        return vaultFactoryStorage().vaultCount;
    }

    function _getHolderVaults(
        address _holder
    ) internal view returns (uint256[] memory) {
        return vaultFactoryStorage().holderVaults[_holder];
    }

    function _isVaultDestroyed(uint256 _vaultId) internal view returns (bool) {
        return vaultFactoryStorage().vaultDestroyed[_vaultId];
    }

    // Drops a vault out of the holder's open-vault list. vaultCount is left
    // alone on purpose: it is the id counter, so decrementing it would hand the
    // next mint an id that is already taken. vaultLocation is kept too, so a
    // destroyed vault stays auditable by id rather than becoming a lookup that
    // reverts.
    function _destroyVault(uint256 _vaultId, address _holder) internal {
        VaultFactoryStorage storage es = vaultFactoryStorage();
        es.vaultDestroyed[_vaultId] = true;

        uint256[] storage vaultIds = es.holderVaults[_holder];
        for (uint256 i = 0; i < vaultIds.length; i++) {
            if (vaultIds[i] != _vaultId) continue;
            vaultIds[i] = vaultIds[vaultIds.length - 1];
            vaultIds.pop();
            return;
        }
        revert("VaultFactory: vault is not held by the given holder");
    }
}

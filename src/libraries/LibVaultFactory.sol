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
        bool initialized;
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

    function _isInitialized() internal view returns (bool) {
        return vaultFactoryStorage().initialized;
    }
}

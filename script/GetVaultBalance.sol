pragma solidity ^0.8.26;
import "../lib/forge-std/src/Script.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IOwnership.sol";
import "../src/interfaces/IErc20PetroCoin.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";

import "../src/facets/Erc20PetroCoinFacet.sol";
import "../src/Diamond.sol";
import "../test/HelperContract.sol";
import "../lib/forge-std/src/console2.sol";
import "../src/facets/VaultFactoryFacet.sol";

contract GetVaultBalance is Script, HelperContract {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    Erc20PetroCoinFacet erc20;
    VaultFactoryFacet vaultFactory;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;
    IOwnership IOwners;
    IErc20PetroCoin IERC20Petro;
    VaultFactoryFacet IVaultFactory;

    string[] facetNames;
    address[] facetAddressList;
    function run() external {
        IVaultFactory = VaultFactoryFacet(
            address(0xF9eC19da3C8abF819F68B02F8a9bCc7E1BeA2522)
        );

        console.log("PTC Token Address:", address(IVaultFactory));
        uint256[] memory vaultId = IVaultFactory.getHolderVaults(
            address(0xE44D634Db8F33d892CF6Be2910dcDe63bbEF00a2)
        );
        console.log(
            string.concat("vault count: ", vm.toString(vaultId.length))
        );
        for (uint256 i = 0; i < vaultId.length; i++) {
            console.log(string.concat("vaultId: ", vm.toString(vaultId[i])));
            uint256 vaultBalance = IVaultFactory.getVaultBalanceById(
                vaultId[i]
            );
            console.log(
                string.concat("vaultBalance: ", vm.toString(vaultBalance))
            );
            address beneficiary = IVaultFactory.getVaultInitialBeneficiary(vaultId[i]);
            console.log("beneficiary:", beneficiary);
            uint256 releaseTime = IVaultFactory.getVaultReleaseTime(vaultId[i]);
            console.log(
                string.concat("releaseTime: ", vm.toString(releaseTime))
            );
        }
    }
}

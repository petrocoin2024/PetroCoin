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
import "../lib/forge-std/src/console.sol";
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
        vm.startBroadcast();
        IVaultFactory = VaultFactoryFacet(
            address(0xdCfB65CC9f69D78dDFA30f47eefD1594466fB47D)
        );

        console.log("Diamond Address:", address(IVaultFactory));

        console.log("number of vaults made:", IVaultFactory.vaultCount());
        console.log(
            "beneficiary of first vault:",
            IVaultFactory.getVaultBeneficiary(1)
        );
        uint256[] memory vaultIds = IVaultFactory.getHolderVaults(
            address(0x993A040a022fB002f36E0Fb0831e5DB0050cFFcD)
        );

        console.log(
            "checking balance for account:",
            address(0x993A040a022fB002f36E0Fb0831e5DB0050cFFcD)
        );
        console.log("vault #:", vaultIds.length);
        for (uint256 i = 0; i < vaultIds.length; i++) {
            console.log("vaultId:", vaultIds[i]);
            uint256 vaultBalance = IVaultFactory.getVaultBalanceById(
                vaultIds[i]
            );
            console.log("vaultBalance:", vaultBalance);
            address beneficiary = IVaultFactory.getVaultBeneficiary(
                vaultIds[i]
            );
            console.log("beneficiary:", beneficiary);
            uint256 releaseTime = IVaultFactory.getVaultReleaseTime(
                vaultIds[i]
            );
            console.log("releaseTime:", releaseTime);
        }

        vm.stopBroadcast();
    }
}

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

contract UpdateSepoliaV2 is Script, HelperContract {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    Erc20PetroCoinFacet erc20V2;
    VaultFactoryFacet vaultFactoryV2;

    IDiamondLoupe ILoupe;
    IDiamondCut ICut;
    IErc20PetroCoin IERC20PetroV2;
    VaultFactoryFacet IVaultFactoryV2;

    function run() external {
        vm.startBroadcast();

        //deploy new contract for erc20 and vault factory. At present, erc20 contract defines the token time lock functionality,
        // so the new version of the timelock should be available with that deployment.
        erc20V2 = new Erc20PetroCoinFacet();
        vaultFactoryV2 = new VaultFactoryFacet();

        address diamondAddress = 0x6B4a4Ac71E3B7757364637A90e82fA7b546153B9; // TODO: Replace with actual Diamond address

        // Step 3: Get the IDiamondCut interface for the Diamond proxy
        ICut = IDiamondCut(diamondAddress);

        ILoupe = IDiamondLoupe(diamondAddress);
        bytes4[] memory originalErc20Selectors = ILoupe.facetFunctionSelectors(
            0xe26967488772F9a2a24378D1F3C155bA381CCca9
        );
        bytes4[] memory originalVaultFactorySelectors = ILoupe
            .facetFunctionSelectors(0x63e84b699a9ea01893575994DAb20DC00692b1af);

        bytes4[] memory vaultAddSelectors = new bytes4[](1);
        vaultAddSelectors[0] = vaultFactoryV2
            .getVaultFractionalOwnerBalance
            .selector;

        FacetCut[] memory cutV2 = new FacetCut[](3);
        cutV2[0] = FacetCut({
            facetAddress: address(erc20V2),
            action: FacetCutAction.Replace,
            functionSelectors: originalErc20Selectors
        });
        cutV2[1] = FacetCut({
            facetAddress: address(vaultFactoryV2),
            action: FacetCutAction.Replace,
            functionSelectors: originalVaultFactorySelectors
        });
        cutV2[2] = FacetCut({
            facetAddress: address(vaultFactoryV2),
            action: FacetCutAction.Add,
            functionSelectors: vaultAddSelectors
        });

        ICut.diamondCut(cutV2, address(0x0), "");

        vm.stopBroadcast();
    }
}

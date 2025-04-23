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
        bytes4[] memory replaceSelectors = new bytes4[](2);
        replaceSelectors[0] = erc20V2.mintProducerTokens.selector;
        replaceSelectors[1] = erc20V2.mintTreasuryTokens.selector;

        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = vaultFactoryV2
            .getVaultFractionalOwnerBalance
            .selector;

        FacetCut[] memory cutV2 = new FacetCut[](2);
        cutV2[0] = FacetCut({
            facetAddress: address(erc20V2),
            action: FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });
        cutV2[1] = FacetCut({
            facetAddress: address(vaultFactoryV2),
            action: FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        ICut.diamondCut(cutV2, address(0x0), "");

        vm.stopBroadcast();
    }
}

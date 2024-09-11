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

contract ViewActiveFacets is Script, HelperContract {
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
        console.log("ViewActiveFacets");
        ILoupe = IDiamondLoupe(
            address(0xdCfB65CC9f69D78dDFA30f47eefD1594466fB47D)
        );
        console.log("ILoupe: ", address(ILoupe));
        address[] memory facetsAddys = ILoupe.facetAddresses();
        console.log("facetsAddy #:", facetsAddys.length);
        for (uint256 i = 0; i < facetsAddys.length; i++) {
            bytes4[] memory selectors = ILoupe.facetFunctionSelectors(
                facetsAddys[i]
            );
            for (uint256 j = 0; j < selectors.length; j++) {
                console.logBytes4(selectors[j]);
            }
            console.log("facetsAddy: ", facetsAddys[i]);
        }
        vm.stopBroadcast();
    }
}

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

contract ChangeOwner is Script, HelperContract {
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

        IOwners = IOwnership(
            address(0x3167Dc94b4FF583A95170bB6eb3E56d2E14Cb0b1)
        );
        address owner = IOwners.owner();
        console.log("original owner:", owner);
        IOwners.transferOwnership(
            address(0xdb90Fa67F10e9e58e5c9C768309E2facF30E2246)
        );

        address newOwner = IOwners.owner();
        console.log("newOwner:", newOwner);
        vm.stopBroadcast();
    }
}

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

contract DeployDiamondSepolia is Script, HelperContract {
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
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc20 = new Erc20PetroCoinFacet();
        vaultFactory = new VaultFactoryFacet();

        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "Erc20PetroCoinFacet",
            "VaultFactoryFacet"
        ];

        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: address(0x993A040a022fB002f36E0Fb0831e5DB0050cFFcD),
            majorityApprover: address(
                0x5d625Bc3aC183307439EF12059167BD7c721Ab82
            ),
            init: address(0),
            initCalldata: " "
        });

        // FacetCut with CutFacet for initialization
        FacetCut[] memory cut0 = new FacetCut[](1);
        cut0[0] = FacetCut({
            facetAddress: address(dCutFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        // deploy diamond
        diamond = new Diamond(cut0, _args);

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        // initialise interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
        IOwners = IOwnership(address(diamond));

        //upgrade diamond
        ICut.diamondCut(cut, address(0x0), "");

        // get all addresses

        //Add Erc20 Functionality
        FacetCut[] memory cutErc20 = new FacetCut[](1);
        cutErc20[0] = FacetCut({
            facetAddress: address(erc20),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("Erc20PetroCoinFacet")
        });

        ICut.diamondCut(cutErc20, address(0x0), "");
        facetAddressList = ILoupe.facetAddresses();
        IERC20Petro = IErc20PetroCoin(address(diamond));

        // array of functions to add
        FacetCut[] memory vaultFactoryCut = new FacetCut[](1);
        vaultFactoryCut[0] = FacetCut({
            facetAddress: address(vaultFactory),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VaultFactoryFacet")
        });

        // add functions to diamond
        ICut.diamondCut(vaultFactoryCut, address(0x0), "");
        IVaultFactory = VaultFactoryFacet(address(diamond));

        //initialize ERC20 Facet
        IERC20Petro.initErc20PetroCoin(
            "PetroCoin",
            "PTCN",
            1000000,
            18,
            47304000,
            31536000
        );
        // IVaultFactory.initializeVaultFactory();

        IERC20Petro.transferTreasuryTokens(address(this), 1000);
        console.log("Diamond Address: ", address(diamond));
        uint256 balanceOfOwner = IERC20Petro.balanceOf(
            IVaultFactory.getVaultLocationById(1)
        );
        console.log("Tokens locked in vault: ", balanceOfOwner);
        vm.stopBroadcast();
    }
}

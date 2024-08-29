// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "../src/interfaces/IERC20.sol";
import "./TestStates.sol";
// test proper deployment of diamond
contract TestDeployDiamondWithOwners is StateDeployDiamond {
    function testOwnersandMajoritySet() public view {
        address owner = IOwners.owner();
        address majorityApprover = IOwners.majorityApprover();
        assertEq(owner, address(this));
        assertEq(
            majorityApprover,
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
        );
    }

    function testOwnersTransfer() public {
        // transfer ownership
        IOwners.transferOwnership(address(0x0));
        assertEq(IOwners.owner(), address(0x0));
        //! specify revert reason
        vm.expectRevert();
        IOwners.transferOwnership(address(this));
    }

    function testTransferMajorityApprovalTransfer() public {
        // transfer majority approval
        IOwners.transferMajorityApproval(address(0x0));
        assertEq(IOwners.majorityApprover(), address(0x0));
        IOwners.transferOwnership(address(0x0));
        vm.expectRevert();
        IOwners.transferMajorityApproval(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );
    }
}

//test ERC20 Lib Facet

contract TestERC20Facet is StateDeployDiamond {
    function testERC20FacetInitialized() public {
        //initialize ERC20 Facet
        IERC20Petro.initErc20PetroCoin("PetroCoin", "PC", 1000000, 18);

        assertEq(IERC20Petro.name(), "PetroCoin");
        assertEq(IERC20Petro.symbol(), "PC");
        assertEq(IERC20Petro.totalSupply(), 1000000);
        assertEq(IERC20Petro.decimals(), 18);

        vm.expectRevert();
        IERC20Petro.initErc20PetroCoin("PetroCoin", "PC", 1000000, 18);
    }

    //todo: test ERC20 functions
}

contract TestFactoryVault is StateAddedFactory {
    function testFactoryVaultInitialized() public {
        //initialize Vault Factory Facet
        IVaultFactory.initializeVaultFactory();

        assertEq(IVaultFactory.vaultCount(), 0);
        assertTrue(IVaultFactory.isInitialized());
    }

    function testVaultCreation() public {
        //create token timelock
        IERC20Petro.initErc20PetroCoin("PetroCoin", "PC", 1000000, 18);
        uint256 initialVaultCount = IVaultFactory.vaultCount();
        IERC20 IERC20P = IERC20(address(IERC20Petro));
        TokenTimelock timelock = IVaultFactory.createTokenTimelock(
            IERC20P,
            address(this),
            block.timestamp + 100000000
        );

        assertEq(IVaultFactory.vaultCount(), initialVaultCount + 1);
        uint256[] memory vaultIdArray = IVaultFactory.getHolderVaults(
            address(this)
        );
        assertEq(vaultIdArray[0], 1);
        assertEq(vaultIdArray.length, 1);
        assertEq(IVaultFactory.getVaultLocationById(1), address(timelock));

        TokenTimelock timelock2 = IVaultFactory.createTokenTimelock(
            IERC20P,
            address(this),
            block.timestamp + 200000000
        );
        vaultIdArray = IVaultFactory.getHolderVaults(address(this));
        assertEq(IVaultFactory.vaultCount(), initialVaultCount + 2);
        assertEq(vaultIdArray[0], 1);
        assertEq(vaultIdArray[1], 2);
        assertEq(vaultIdArray.length, 2);
        assertEq(IVaultFactory.getVaultLocationById(2), address(timelock2));
    }

    function testVaultLock() public {
        //create token timelock
        IERC20Petro.initErc20PetroCoin("PetroCoin", "PC", 1000000, 18);
        IERC20 IERC20P = IERC20(address(IERC20Petro));
        TokenTimelock timelock = IVaultFactory.createTokenTimelock(
            IERC20P,
            address(this),
            block.timestamp + 100000000
        );

        //check if tokens locked
        vm.expectRevert();
        timelock.release();

        //fast forward time to unlock tokens
        vm.warp(block.timestamp + 100000001);
        timelock.release();
    }
}
// // test proper deployment of diamond
// contract TestDeployDiamond is StateDeployDiamond {
//     function test1HasThreeFacets() public view {
//         console.log("size of facetAddressList1:", facetAddressList.length);
//         assertEq(facetAddressList.length, 3);
//     }

//     function test2FacetsHaveCorrectSelectors() public {
//         for (uint i = 0; i < facetAddressList.length; i++) {
//             bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
//                 facetAddressList[i]
//             );
//             bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);
//             assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
//         }
//     }

//     function test3SelectorsAssociatedWithCorrectFacet() public {
//         for (uint i = 0; i < facetAddressList.length; i++) {
//             bytes4[] memory fromGenSelectors = generateSelectors(facetNames[i]);
//             for (uint j = 0; i < fromGenSelectors.length; i++) {
//                 assertEq(
//                     facetAddressList[i],
//                     ILoupe.facetAddress(fromGenSelectors[j])
//                 );
//             }
//         }
//     }
// }

// contract TestAddFacet1 is StateAddFacet1 {
//     function test4AddTest1FacetFunctions() public {
//         // check if functions added to diamond
//         bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
//             address(test1Facet)
//         );
//         bytes4[] memory fromGenSelectors = removeElement(
//             uint(0),
//             generateSelectors("Test1Facet")
//         );
//         assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
//     }

//     function test5CanCallTest1FacetFunction() public {
//         // try to call function on new Facet
//         Test1Facet(address(diamond)).test1Func10();
//     }

//     function test6ReplaceSupportsInterfaceFunction() public {
//         // get supportsInterface selector from positon 0
//         bytes4[] memory fromGenSelectors = new bytes4[](1);
//         fromGenSelectors[0] = generateSelectors("Test1Facet")[0];

//         // struct to replace function
//         FacetCut[] memory cutTest1 = new FacetCut[](1);
//         cutTest1[0] = FacetCut({
//             facetAddress: address(test1Facet),
//             action: FacetCutAction.Replace,
//             functionSelectors: fromGenSelectors
//         });

//         // replace function by function on Test1 facet
//         ICut.diamondCut(cutTest1, address(0x0), "");

//         // check supportsInterface method connected to test1Facet
//         assertEq(address(test1Facet), ILoupe.facetAddress(fromGenSelectors[0]));
//     }
// }

// contract TestAddFacet2 is StateAddFacet2 {
//     function test7AddTest2FacetFunctions() public {
//         // check if functions added to diamond
//         bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
//             address(test2Facet)
//         );
//         bytes4[] memory fromGenSelectors = generateSelectors("Test2Facet");
//         assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
//     }

//     function test8RemoveSomeTest2FacetFunctions() public {
//         bytes4[] memory functionsToKeep = new bytes4[](5);
//         functionsToKeep[0] = test2Facet.test2Func1.selector;
//         functionsToKeep[1] = test2Facet.test2Func5.selector;
//         functionsToKeep[2] = test2Facet.test2Func6.selector;
//         functionsToKeep[3] = test2Facet.test2Func19.selector;
//         functionsToKeep[4] = test2Facet.test2Func20.selector;

//         bytes4[] memory selectors = ILoupe.facetFunctionSelectors(
//             address(test2Facet)
//         );
//         for (uint i = 0; i < functionsToKeep.length; i++) {
//             selectors = removeElement(functionsToKeep[i], selectors);
//         }

//         // array of functions to remove
//         FacetCut[] memory facetCut = new FacetCut[](1);
//         facetCut[0] = FacetCut({
//             facetAddress: address(0x0),
//             action: FacetCutAction.Remove,
//             functionSelectors: selectors
//         });

//         // add functions to diamond
//         ICut.diamondCut(facetCut, address(0x0), "");

//         bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
//             address(test2Facet)
//         );
//         assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));
//     }

//     function test9RemoveSomeTest1FacetFunctions() public {
//         bytes4[] memory functionsToKeep = new bytes4[](3);
//         functionsToKeep[0] = test1Facet.test1Func2.selector;
//         functionsToKeep[1] = test1Facet.test1Func11.selector;
//         functionsToKeep[2] = test1Facet.test1Func12.selector;

//         bytes4[] memory selectors = ILoupe.facetFunctionSelectors(
//             address(test1Facet)
//         );
//         for (uint i = 0; i < functionsToKeep.length; i++) {
//             selectors = removeElement(functionsToKeep[i], selectors);
//         }

//         // array of functions to remove
//         FacetCut[] memory facetCut = new FacetCut[](1);
//         facetCut[0] = FacetCut({
//             facetAddress: address(0x0),
//             action: FacetCutAction.Remove,
//             functionSelectors: selectors
//         });

//         // add functions to diamond
//         ICut.diamondCut(facetCut, address(0x0), "");

//         bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
//             address(test1Facet)
//         );
//         assertTrue(sameMembers(fromLoupeFacet, functionsToKeep));
//     }

//     function test10RemoveAllExceptDiamondCutAndFacetFunction() public {
//         bytes4[] memory selectors = getAllSelectors(address(diamond));

//         bytes4[] memory functionsToKeep = new bytes4[](2);
//         functionsToKeep[0] = DiamondCutFacet.diamondCut.selector;
//         functionsToKeep[1] = DiamondLoupeFacet.facets.selector;

//         selectors = removeElement(functionsToKeep[0], selectors);
//         selectors = removeElement(functionsToKeep[1], selectors);

//         // array of functions to remove
//         FacetCut[] memory facetCut = new FacetCut[](1);
//         facetCut[0] = FacetCut({
//             facetAddress: address(0x0),
//             action: FacetCutAction.Remove,
//             functionSelectors: selectors
//         });

//         // remove functions from diamond
//         ICut.diamondCut(facetCut, address(0x0), "");

//         Facet[] memory facets = ILoupe.facets();
//         bytes4[] memory testselector = new bytes4[](1);

//         assertEq(facets.length, 2);

//         assertEq(facets[0].facetAddress, address(dCutFacet));

//         testselector[0] = functionsToKeep[0];
//         assertTrue(sameMembers(facets[0].functionSelectors, testselector));

//         assertEq(facets[1].facetAddress, address(dLoupe));
//         testselector[0] = functionsToKeep[1];
//         assertTrue(sameMembers(facets[1].functionSelectors, testselector));
//     }
// }

// contract TestCacheBug is StateCacheBug {
//     function testNoCacheBug() public {
//         bytes4[] memory fromLoupeSelectors = ILoupe.facetFunctionSelectors(
//             address(test1Facet)
//         );

//         assertTrue(containsElement(fromLoupeSelectors, selectors[0]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[1]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[2]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[3]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[4]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[6]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[7]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[8]));
//         assertTrue(containsElement(fromLoupeSelectors, selectors[9]));

//         assertFalse(containsElement(fromLoupeSelectors, ownerSel));
//         assertFalse(containsElement(fromLoupeSelectors, selectors[10]));
//         assertFalse(containsElement(fromLoupeSelectors, selectors[5]));
//     }
// }

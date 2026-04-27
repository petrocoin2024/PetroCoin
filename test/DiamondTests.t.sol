// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "../src/interfaces/IERC20.sol";
import "./TestStates.sol";
import {
    IERC20Errors
} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {
    NotContractOwner,
    NoSelectorsProvidedForFacetForCut,
    CannotAddSelectorsToZeroAddress,
    CannotAddFunctionToDiamondThatAlreadyExists,
    CannotReplaceFunctionsFromFacetWithZeroAddress,
    CannotReplaceImmutableFunction,
    CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet,
    CannotReplaceFunctionThatDoesNotExists
} from "../src/libraries/LibDiamond.sol";
import {stdError} from "../lib/forge-std/src/StdError.sol";
import {VaultFactoryFacetV2} from "./NewVaultFactoryFacet.sol";
import {FunctionNotFound} from "../src/Diamond.sol";
import {AssetCategory} from "../src/facets/Erc20PetroCoinFacet.sol";
contract TestDeployDiamondWithOwners is StateDeployDiamond {
    event TokenDistribution(
        uint256 indexed tokensMinted,
        uint256 indexed estimatedValue,
        AssetCategory indexed assetCategory
    );
    function testOwnersTransfer() public {
        // transfer ownership
        IOwners.transferOwnership(address(0x0));
        assertEq(IOwners.owner(), address(0x0));
        //! specify revert reason
        vm.expectRevert();
        IOwners.transferOwnership(address(this));
    }

    function testChangeLongHoldPeriod() public {
        assertEq(IERC20Petro.getLongHoldPeriod(), 47304000);
        uint256 newHoldPeriod = 1000000;
        IERC20Petro.setLongHoldPeriod(newHoldPeriod);
        assertEq(IERC20Petro.getLongHoldPeriod(), newHoldPeriod);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.expectRevert();
        IERC20Petro.setLongHoldPeriod(1000001);
    }

    function testChangeProducerHoldPeriod() public {
        assertEq(IERC20Petro.getProducerHoldPeriod(), 31536000);
        uint256 newHoldPeriod = 1000000;
        IERC20Petro.setProducerHoldPeriod(newHoldPeriod);
        assertEq(IERC20Petro.getProducerHoldPeriod(), newHoldPeriod);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.expectRevert();
        IERC20Petro.setProducerHoldPeriod(1000001);
    }

    function testReplaceLogic() public {
        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        uint256 vaultBalance = IVaultFactory.getVaultBalanceById(1);
        assertEq(vaultBalance, 1000);
        assertEq(IVaultFactory.getVaultInitialBeneficiary(1), address(this));
        uint256 releaseTime = IVaultFactory.getVaultReleaseTime(1);
        uint256 longHoldPeriod = IERC20Petro.getLongHoldPeriod();
        assertEq(releaseTime, block.timestamp + longHoldPeriod);
        assertEq(IVaultFactory.vaultCount(), 1);
        VaultFactoryFacetV2 newVaultFactory = new VaultFactoryFacetV2();
        FacetCut[] memory cut = new FacetCut[](2);

        bytes4[] memory replaceSelectors = new bytes4[](9);
        uint256 nonce = 0;
        bytes4[] memory addSelectors = new bytes4[](1);
        bytes4[] memory selectors = generateSelectors("VaultFactoryFacetV2");

        bytes4 testingNewSelector = bytes4(
            keccak256("testingNewFunctionLogic()")
        );
        console.log("testingSelector:");
        console.logBytes4(testingNewSelector);
        bytes4 testingOldSelector = bytes4(
            keccak256("createTokenTimelock(address,address,uint256,uint256)")
        );
        console.log("testingOldSelector:");
        console.logBytes4(testingOldSelector);

        bytes4 testSelectorFunction = VaultFactoryFacetV2
            .getHolderVaults
            .selector;
        console.log("testSelectorFunction:");
        console.logBytes4(testSelectorFunction);
        console.log("selectors length: %s", selectors.length);
        for (uint i = 0; i < selectors.length; i++) {
            bytes4 log = (selectors[i]);
            console.logBytes4(log);
            if (log != 0x261cfdb6) {
                replaceSelectors[nonce] = log;
                nonce++;
            } else {
                addSelectors[0] = log;
            }
        }

        cut[0] = FacetCut({
            facetAddress: address(newVaultFactory),
            action: FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });
        cut[1] = FacetCut({
            facetAddress: address(newVaultFactory),
            action: FacetCutAction.Add,
            functionSelectors: addSelectors
        });
        ICut.diamondCut(cut, address(0), "0x");
        VaultFactoryFacetV2 IVaultFactoryV2 = VaultFactoryFacetV2(
            address(diamond)
        );

        assertEq(IVaultFactoryV2.vaultCount(), 1);
        // string memory newLogicResult = IVaultFactoryV2.testingNewFunctionLogic(
        //     2
        // );
        // assertEq(newLogicResult, "new logic");
        assertEq(IVaultFactoryV2.getVaultReleaseTime(1), 42424242);
        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        assertEq(IVaultFactoryV2.vaultCount(), 2);
        // assertEq(IVaultFactoryV2.getVaultReleaseTime(2), 42424242);

        assertEq(IVaultFactoryV2.testingNewFunctionLogic(), "new logic");
    }

    function test_RemoveFunction() public {
        // --- Step 1: prepare selector ---
        bytes4 selector = bytes4(keccak256("foo()"));

        // --- Step 2: add function via facet ---
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        ICut.diamondCut(cut, address(0), "");

        // --- Step 3: confirm selector is registered to the erc20 facet ---
        // We can't actually call `foo()` because the facet doesn't implement
        // it; instead verify the diamond has the selector mapped via the
        // loupe.
        assertEq(ILoupe.facetAddress(selector), address(erc20));

        // --- Step 4: remove function ---
        cut[0] = FacetCut({
            facetAddress: address(0), // must be zero for remove
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        ICut.diamondCut(cut, address(0), "");

        // --- Step 5: confirm selector is gone from the diamond ---
        assertEq(ILoupe.facetAddress(selector), address(0));

        // Calling the removed selector should now revert with
        // FunctionNotFound in the diamond fallback.
        vm.expectRevert(
            abi.encodeWithSelector(FunctionNotFound.selector, selector)
        );

        address(diamond).call(abi.encodeWithSelector(selector));
    }

    function test_RevertsWhenFunctionNotFound() public {
        bytes4 fakeSelector = bytes4(keccak256("nonexistentFunction()"));

        vm.expectRevert(
            abi.encodeWithSelector(FunctionNotFound.selector, fakeSelector)
        );

        // call diamond with unknown selector
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(fakeSelector)
        );
        // Note: when vm.expectRevert is used with a low-level call, the
        // cheatcode consumes the revert and `success` is reported as true.
        success;
    }
    function test_Revert_NoSelectorsProvided() public {
        bytes4[] memory selectors = new bytes4[](0);

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(1),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                NoSelectorsProvidedForFacetForCut.selector,
                address(1)
            )
        );
        ICut.diamondCut(cut, address(0x0), "");
    }

    function test_Revert_AddToZeroAddress() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("foo()"));

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotAddSelectorsToZeroAddress.selector,
                selectors
            )
        );
        ICut.diamondCut(cut, address(0), "");
    }

    function test_Revert_AddExistingFunction() public {
        // Use a selector that is NOT already registered on the diamond,
        // otherwise the first `diamondCut` below reverts before we can
        // exercise the "add again" path.
        bytes4 selector = bytes4(keccak256("brandNewFunction()"));

        // first add
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        ICut.diamondCut(cut, address(0), "");

        // try adding again
        vm.expectRevert(
            abi.encodeWithSelector(
                CannotAddFunctionToDiamondThatAlreadyExists.selector,
                selector
            )
        );

        ICut.diamondCut(cut, address(0), "");
    }

    function test_Revert_ReplaceWithZeroAddress() public {
        bytes4 selector = bytes4(keccak256("foo()"));

        // first add
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        ICut.diamondCut(cut, address(0), "");

        // attempt replace with zero address
        cut[0] = FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceFunctionsFromFacetWithZeroAddress.selector,
                selectors
            )
        );

        ICut.diamondCut(cut, address(0), "");
    }
    function test_Revert_ReplaceImmutableFunction() public {
        // In LibDiamond, `address(this)` (the diamond itself) is treated as
        // the marker for "immutable" selectors — i.e. selectors registered
        // with the diamond as their facet address. To exercise the
        // `CannotReplaceImmutableFunction` branch we must first register a
        // selector that way, then try to Replace it with a different
        // (real) facet address.
        bytes4 selector = bytes4(keccak256("immutableFoo()"));
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = FacetCut({
            facetAddress: address(diamond),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });
        ICut.diamondCut(addCut, address(0), "");

        // Now attempt to Replace the immutable selector with another
        // facet; this must revert with CannotReplaceImmutableFunction.
        FacetCut[] memory replaceCut = new IDiamondCut.FacetCut[](1);
        replaceCut[0] = FacetCut({
            facetAddress: address(dCutFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceImmutableFunction.selector,
                selector
            )
        );

        ICut.diamondCut(replaceCut, address(0), "");
    }

    function test_Revert_ReplaceSameFunctionSameFacet() public {
        bytes4 selector = bytes4(keccak256("foo()"));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        // add
        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        ICut.diamondCut(cut, address(0), "");

        // replace with same facet
        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet
                    .selector,
                selector
            )
        );
        ICut.diamondCut(cut, address(0), "");
    }

    function test_Revert_ReplaceNonexistentFunction() public {
        bytes4 selector = bytes4(keccak256("doesNotExist()"));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(erc20),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                CannotReplaceFunctionThatDoesNotExists.selector,
                selector
            )
        );

        ICut.diamondCut(cut, address(0), "");
    }
}

contract TestERC20Facet is StateDeployDiamond {
    function testERC20FacetInitialized() public {
        assertEq(IERC20Petro.name(), "PetroCoin");
        assertEq(IERC20Petro.symbol(), "PC");
        assertEq(IERC20Petro.totalSupply(), 0);
        assertEq(IERC20Petro.decimals(), 6);

        vm.expectRevert();
        IERC20Petro.initErc20PetroCoin(
            "PetroCoin",
            "PC",
            1000000,
            18,
            47304000,
            31536000
        );
    }

    function testTreasureryBalance() public {
        assertEq(IERC20Petro.getMintedTreasuryTokens(), 0);
        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        assertEq(IERC20Petro.getMintedTreasuryTokens(), 1000);
    }

    function testTreasuryMint() public {
        vm.startPrank(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        vm.expectRevert();
        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        vm.stopPrank();

        TokenTimelock timeLockVault = IERC20Petro.mintTreasuryTokens(
            address(this),
            1000
        );

        uint256[] memory ownerVaults = IVaultFactory.getHolderVaults(
            address(this)
        );
        assertEq(ownerVaults.length, 1);
        assertEq(IERC20Petro.balanceOf(address(timeLockVault)), 1000);
    }

    function testAllowanceAndTransferFrom() public {
        console.log("Testing allowance and transferFrom...");

        TokenTimelock timeLockVault = IERC20Petro.mintTreasuryTokens(
            address(this),
            1000
        );

        address recipient = address(0x123);

        uint256 longHoldPeriod = IERC20Petro.getLongHoldPeriod();
        vm.warp(block.timestamp + longHoldPeriod + 1);

        IVaultFactory.releaseVaultTokens(1);

        // --- INITIAL APPROVAL ---
        IERC20Petro.approve(recipient, 500);
        assertEq(IERC20Petro.allowance(address(this), recipient), 500);

        // --- INCREASE ALLOWANCE ---
        IERC20Petro.increaseAllowance(recipient, 200);
        assertEq(IERC20Petro.allowance(address(this), recipient), 700);

        // --- DECREASE ALLOWANCE ---
        IERC20Petro.decreaseAllowance(recipient, 100);
        assertEq(IERC20Petro.allowance(address(this), recipient), 600);

        // --- TRANSFER FROM ---
        console.log(
            "sender balance before transferFrom: %s",
            IERC20Petro.balanceOf(address(this))
        );

        vm.prank(recipient);
        IERC20Petro.transferFrom(address(this), recipient, 300);

        assertEq(IERC20Petro.balanceOf(recipient), 300);
        assertEq(IERC20Petro.allowance(address(this), recipient), 300);

        // --- DECREASE BELOW ZERO SHOULD REVERT ---
        vm.expectRevert("ERC20: decreased allowance below zero");
        IERC20Petro.decreaseAllowance(recipient, 500); // only 300 left
    }
}

contract TestFactoryVault is StateDeployDiamond {
    // function testFactoryVaultInitialized() public {
    //     //initialize Vault Factory Facet
    //     IVaultFactory.initializeVaultFactory();

    //     assertEq(IVaultFactory.vaultCount(), 0);
    //     assertTrue(IVaultFactory.isInitialized());
    // }

    function testVaultCreation() public {
        //create token timelock

        uint256 initialVaultCount = IVaultFactory.vaultCount();
        assertEq(initialVaultCount, 0);
        IERC20 IERC20P = IERC20(address(IERC20Petro));
        TokenTimelock timelock = IVaultFactory.createTokenTimelock(
            IERC20P,
            address(this),
            block.timestamp + 100000000,
            42424242
        );

        assertEq(IVaultFactory.vaultCount(), initialVaultCount + 1);
        uint256[] memory vaultIdArray = IVaultFactory.getHolderVaults(
            address(this)
        );
        assertEq(vaultIdArray[0], 1);
        assertEq(vaultIdArray.length, 1);
        assertEq(IVaultFactory.getVaultLocationById(1), address(timelock));
        assertEq(timelock.balanceOf(address(this)), 42424242);

        TokenTimelock timelock2 = IVaultFactory.createTokenTimelock(
            IERC20P,
            address(this),
            block.timestamp + 200000000,
            242424242
        );
        vaultIdArray = IVaultFactory.getHolderVaults(address(this));
        assertEq(IVaultFactory.vaultCount(), initialVaultCount + 2);
        assertEq(vaultIdArray[0], 1);
        assertEq(vaultIdArray[1], 2);
        assertEq(vaultIdArray.length, 2);
        assertEq(IVaultFactory.getVaultLocationById(2), address(timelock2));
        assertEq(timelock2.balanceOf(address(this)), 242424242);
    }

    function testTreasuryVaultLock() public {
        //check if tokens locked

        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        uint256 vaultBalance = IVaultFactory.getVaultBalanceById(1);
        uint256 vaultAddressBalance = IERC20Petro.balanceOf(
            IVaultFactory.getVaultLocationById(1)
        );
        assertEq(vaultBalance, 1000);
        assertEq(vaultAddressBalance, 1000);
        address vaultContractAddress = IVaultFactory.getVaultLocationById(1);
        TokenTimelock vaultContract = TokenTimelock(vaultContractAddress);
        assertEq(vaultContract.balanceOf(address(this)), 1000);
        assertEq(IERC20Petro.balanceOf(address(this)), 0);
        assertEq(IVaultFactory.getVaultInitialBeneficiary(1), address(this));
        uint256 releaseTime = IVaultFactory.getVaultReleaseTime(1);
        uint256 longHoldPeriod = IERC20Petro.getLongHoldPeriod();
        assertEq(releaseTime, block.timestamp + longHoldPeriod);

        vm.expectRevert("TokenTimelock: current time is before release time");
        IVaultFactory.releaseVaultTokens(1);

        vm.warp(releaseTime + 1);
        IVaultFactory.releaseVaultTokens(1);
        assertEq(IERC20Petro.balanceOf(address(this)), 1000);
        assertEq(IERC20Petro.balanceOf(address(vaultContract)), 0);
        assert(vaultContract.isReleased());
        assertEq(vaultContract.balanceOf(address(this)), 0);
    }

    function testVaultInitialBeneficiary() public {
        IERC20Petro.mintTreasuryTokens(address(this), 1000);
        uint256 vaultBalance = IVaultFactory.getVaultBalanceById(1);
        assertEq(vaultBalance, 1000);
        assertEq(IERC20Petro.balanceOf(address(this)), 0);
        assertEq(IVaultFactory.getVaultInitialBeneficiary(1), address(this));

        address vaultContractAddress = IVaultFactory.getVaultLocationById(1);
        TokenTimelock vaultContract = TokenTimelock(vaultContractAddress);
        vaultContract.initialBeneficiary();
        assertEq(vaultContract.initialBeneficiary(), address(this));
    }

    function testVaultDistributedShares() public {
        AssetCategory category = AssetCategory.ConductiveAndRareEarthMetals;
        vm.expectEmit(true, true, false, true);
        emit Transfer(
            address(0),
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            1000
        );

        vm.expectEmit(true, true, true, false);
        emit TokenDistribution(1000, 1000000, category);
        IERC20Petro.mintProducerTokens(
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            1000,
            1000000,
            category
        );
        address vaultContractAddress = IVaultFactory.getVaultLocationById(1);
        TokenTimelock vaultContract = TokenTimelock(vaultContractAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                address(this),
                0,
                500
            )
        );
        vaultContract.transfer(address(this), 500);
        vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vaultContract.transfer(address(this), 500);

        assertEq(vaultContract.balanceOf(address(this)), 500);
        vm.stopPrank();
        vaultContract.transfer(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 200);
        assertEq(vaultContract.balanceOf(address(this)), 300);
        uint256 fractionalOwnershipBalance = vaultContract.balanceOf(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
        assertEq(
            IVaultFactory.getVaultFractionalOwnerBalance(
                1,
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            ),
            fractionalOwnershipBalance
        );
        uint256 releaseTime = IVaultFactory.getVaultReleaseTime(1);

        vm.warp(releaseTime + 1);
        IVaultFactory.releaseVaultTokens(1);
        assertEq(IERC20Petro.balanceOf(address(this)), 300);
        vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IVaultFactory.releaseVaultTokens(1);
        assertEq(
            IERC20Petro.balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            700
        );
    }
}

contract TestHoldPeriods is StateDeployDiamond {
    function testMintProducerTokens() public {
        vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.expectRevert(
            abi.encodeWithSelector(
                NotContractOwner.selector,
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                address(this)
            )
        );
        IERC20Petro.mintProducerTokens(address(this), 1000);
        vm.stopPrank();
        assertEq(IERC20Petro.totalSupply(), 0);
        uint256 initialVaults = IVaultFactory.vaultCount();
        uint256[] memory beneficiaryVaultsArray = IVaultFactory.getHolderVaults(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );
        assertEq(beneficiaryVaultsArray.length, 0);
        IERC20Petro.mintProducerTokens(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            1000000000
        );
        uint256[] memory beneficiaryVaultsArray2 = IVaultFactory
            .getHolderVaults(
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            );
        assertEq(beneficiaryVaultsArray2.length, 1);
        TokenTimelock vaultContract = TokenTimelock(
            IVaultFactory.getVaultLocationById(beneficiaryVaultsArray2[0])
        );
        assertEq(vaultContract.balanceOf(address(this)), 0);
        assertEq(
            vaultContract.balanceOf(
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            ),
            1000000000
        );
        assertEq(IERC20Petro.totalSupply(), 1000000000);
        assertEq(IVaultFactory.vaultCount(), initialVaults + 1);
        assertEq(
            IVaultFactory.getVaultInitialBeneficiary(
                beneficiaryVaultsArray2[0]
            ),
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );

        assertEq(
            IVaultFactory.getVaultBalanceById(beneficiaryVaultsArray2[0]),
            1000000000
        );
        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        vm.expectRevert("TokenTimelock: current time is before release time");
        IVaultFactory.releaseVaultTokens(beneficiaryVaultsArray2[0]);
        assertEq(
            IERC20Petro.balanceOf(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            0
        );
        uint256 releaseTime = IVaultFactory.getVaultReleaseTime(
            beneficiaryVaultsArray2[0]
        );
        uint256 producerHoldPeriod = IERC20Petro.getProducerHoldPeriod();
        assertEq(releaseTime, block.timestamp + producerHoldPeriod);
        vm.warp(releaseTime + 1);
        IVaultFactory.releaseVaultTokens(beneficiaryVaultsArray2[0]);

        assertEq(
            IERC20Petro.balanceOf(0x70997970C51812dc3A010C7d01b50e0d17dc79C8),
            1000000000
        );
        assertEq(
            vaultContract.balanceOf(
                address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
            ),
            0
        );
        assert(vaultContract.isReleased());
        assertEq(vaultContract.totalSupply(), 0);
    }
}

// contract TestAddedFunctions is StateDeployDiamond {
//     function testAddedFunctions() public {}
// }

contract TestPausable is StateDeployDiamond {
    function testTransferWhenPaused() public {
        bool pauseStatus = IERC20Petro.isPaused();
        assertEq(pauseStatus, false);
        IERC20Petro.pause();
        pauseStatus = IERC20Petro.isPaused();
        assertEq(pauseStatus, true);
        vm.expectRevert();
        IERC20Petro.transfer(address(this), 1000);
        vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.expectRevert();
        IERC20Petro.pause();
        vm.stopPrank();
        IERC20Petro.unpause();
        uint256 vaultCount = IVaultFactory.vaultCount();
        assertEq(vaultCount, 0);
        IERC20Petro.mintTreasuryTokens(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            1000
        );
        vaultCount = IVaultFactory.vaultCount();
        assertEq(vaultCount, 1);
        uint256 vaultReleaseTime = IVaultFactory.getVaultReleaseTime(1);
        uint256 longHoldPeriod = IERC20Petro.getLongHoldPeriod();
        assertEq(vaultReleaseTime, block.timestamp + longHoldPeriod);
        uint256 vaultBalance = IVaultFactory.getVaultBalanceById(1);
        assertEq(vaultBalance, 1000);
        vm.warp(vaultReleaseTime + 1);
        IERC20Petro.pause();
        vm.expectRevert();
        IVaultFactory.releaseVaultTokens(1);
        IERC20Petro.unpause();
        vm.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IVaultFactory.releaseVaultTokens(1);
        assertEq(
            IERC20Petro.balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            1000
        );
    }
}
// // test proper deployment of diamond

//TO TEST
// NEW hold period changes the hold period of new time lock vaults
//todo: full rPTCN tests

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

    function testMajorityApprovalTransfer() public {
        // transfer majority approval
        IOwners.transferMajorityApproval(address(0x0));
        assertEq(IOwners.majorityApprover(), address(0x0));
        IOwners.transferOwnership(address(0x0));
        vm.expectRevert();
        IOwners.transferMajorityApproval(
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
        );
    }

    function testChangeOwnerHoldPeriod() public {
        assertEq(IERC20Petro.getOwnerHoldPeriod(), 47304000);
        uint256 newHoldPeriod = 1000000;
        IERC20Petro.setOwnerHoldPeriod(newHoldPeriod);
        assertEq(IERC20Petro.getOwnerHoldPeriod(), newHoldPeriod);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        vm.expectRevert();
        IERC20Petro.setOwnerHoldPeriod(1000001);
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
}

//test ERC20 Lib Facet

contract TestERC20Facet is StateDeployDiamond {
    function testERC20FacetInitialized() public {
        assertEq(IERC20Petro.name(), "PetroCoin");
        assertEq(IERC20Petro.symbol(), "PC");
        assertEq(IERC20Petro.totalSupply(), 1000000);
        assertEq(IERC20Petro.decimals(), 18);

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
        assertEq(IERC20Petro.getTreasureryBalance(), 1000000);
    }

    function testTreasuryWithdrawal() public {
        assertEq(IERC20Petro.getTreasureryBalance(), 1000000);

        vm.startPrank(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        vm.expectRevert();
        IERC20Petro.transferTreasuryTokens(address(this), 1000);
        vm.stopPrank();
        TokenTimelock timeLockVault = IERC20Petro.transferTreasuryTokens(
            address(this),
            1000
        );

        uint256[] memory ownerVaults = IVaultFactory.getHolderVaults(
            address(this)
        );
        assertEq(ownerVaults.length, 1);
        assertEq(IERC20Petro.balanceOf(address(timeLockVault)), 1000);
    }
    //todo: test ERC20 functions
}

contract TestFactoryVault is StateDeployDiamond {
    function testFactoryVaultInitialized() public {
        //initialize Vault Factory Facet
        IVaultFactory.initializeVaultFactory();

        assertEq(IVaultFactory.vaultCount(), 0);
        assertTrue(IVaultFactory.isInitialized());
    }

    function testVaultCreation() public {
        //create token timelock

        uint256 initialVaultCount = IVaultFactory.vaultCount();
        assertEq(initialVaultCount, 0);
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

    function testTreasuryVaultLock() public {
        //check if tokens locked

        IERC20Petro.transferTreasuryTokens(address(this), 1000);
        uint256 vaultBalance = IVaultFactory.getVaultBalanceById(1);

        assertEq(vaultBalance, 1000);

        assertEq(IERC20Petro.balanceOf(address(this)), 0);
        assertEq(IVaultFactory.getVaultBeneficiary(1), address(this));
        uint256 releaseTime = IVaultFactory.getVaultReleaseTime(1);
        uint256 ownerHoldPeriod = IERC20Petro.getOwnerHoldPeriod();
        assertEq(releaseTime, block.timestamp + ownerHoldPeriod);

        vm.expectRevert("TokenTimelock: current time is before release time");
        IVaultFactory.releaseVaultTokens(1);

        vm.warp(releaseTime + 1);
        IVaultFactory.releaseVaultTokens(1);
        assertEq(IERC20Petro.balanceOf(address(this)), 1000);
    }
}
// // test proper deployment of diamond

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./TestStates.sol";
import "../src/libraries/LibERC20Enhanced.sol";
import {TokenTimelock} from "../src/utils/TokenTimelock.sol";

contract TestDestroyVaults is StateDeployDiamond {
    event VaultDestroyed(
        uint256 indexed vaultId,
        address indexed holder,
        uint256 tokensBurned
    );

    address constant PRODUCER = 0x55eb317fF962dE0c9753CF7bFADbbEF4aaa789c8;
    address constant OTHER_PRODUCER =
        0xCf3b547c78b92C1e5C1A05d622E655Dc6d18Fd6B;
    address constant NOT_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function mintTo(address account, uint256 amount) internal returns (uint256) {
        IERC20Petro.mintProducerTokens(
            account,
            amount,
            1,
            LibErc20Enhanced.AssetCategory.Services
        );
        return IVaultFactory.vaultCount();
    }

    function ids(uint256 a) internal pure returns (uint256[] memory list) {
        list = new uint256[](1);
        list[0] = a;
    }

    function ids(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256[] memory list) {
        list = new uint256[](2);
        list[0] = a;
        list[1] = b;
    }

    function testDestroyBurnsTokensAndClosesVault() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        address vaultAddress = IVaultFactory.getVaultLocationById(vaultId);
        uint256 supplyBefore = IERC20Petro.totalSupply();

        vm.expectEmit(true, true, true, true);
        emit VaultDestroyed(vaultId, PRODUCER, 19500000000);
        IERC20Petro.destroyVaults(ids(vaultId));

        assertEq(IERC20Petro.balanceOf(vaultAddress), 0);
        assertEq(IERC20Petro.totalSupply(), supplyBefore - 19500000000);
        assertEq(IVaultFactory.getVaultBalanceById(vaultId), 0);
        assertTrue(IVaultFactory.isVaultDestroyed(vaultId));
        assertEq(IVaultFactory.getHolderVaults(PRODUCER).length, 0);
    }

    // The whole point of the array argument: one bad distribution, one tx.
    function testDestroysManyVaultsInOneCall() public {
        uint256 keep = mintTo(PRODUCER, 500000000);
        uint256 dupeA = mintTo(PRODUCER, 19500000000);
        uint256 dupeB = mintTo(PRODUCER, 2000000000);
        uint256 supplyBefore = IERC20Petro.totalSupply();

        IERC20Petro.destroyVaults(ids(dupeA, dupeB));

        assertEq(
            IERC20Petro.totalSupply(),
            supplyBefore - 19500000000 - 2000000000
        );

        // The surviving vault is untouched and is all that is left open.
        uint256[] memory open = IVaultFactory.getHolderVaults(PRODUCER);
        assertEq(open.length, 1);
        assertEq(open[0], keep);
        assertEq(IVaultFactory.getVaultBalanceById(keep), 500000000);
        assertFalse(IVaultFactory.isVaultDestroyed(keep));
    }

    // Removal is a swap-and-pop, so make sure it removes the right entries no
    // matter where in the list they sit.
    function testRemovesFromTheMiddleOfTheHolderList() public {
        uint256 first = mintTo(PRODUCER, 100000000);
        uint256 middle = mintTo(PRODUCER, 200000000);
        uint256 last = mintTo(PRODUCER, 300000000);

        IERC20Petro.destroyVaults(ids(middle));

        uint256[] memory open = IVaultFactory.getHolderVaults(PRODUCER);
        assertEq(open.length, 2);
        assertTrue(open[0] == first || open[1] == first);
        assertTrue(open[0] == last || open[1] == last);
        assertTrue(open[0] != middle && open[1] != middle);
    }

    // vaultCount is the id counter, not a live tally. If destroying decremented
    // it, the next mint would collide with an existing vault id.
    function testNextMintDoesNotReuseADestroyedId() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        address destroyedLocation = IVaultFactory.getVaultLocationById(vaultId);

        IERC20Petro.destroyVaults(ids(vaultId));
        assertEq(IVaultFactory.vaultCount(), vaultId);

        uint256 nextId = mintTo(OTHER_PRODUCER, 10500000000);
        assertEq(nextId, vaultId + 1);
        assertTrue(
            IVaultFactory.getVaultLocationById(nextId) != destroyedLocation
        );
        assertEq(IVaultFactory.getVaultLocationById(vaultId), destroyedLocation);
    }

    // A destroyed vault has no tokens to pay out, so release must say so rather
    // than failing deep inside the timelock's transfer.
    function testReleaseRejectsDestroyedVault() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        IERC20Petro.destroyVaults(ids(vaultId));

        vm.warp(block.timestamp + IERC20Petro.getProducerHoldPeriod() + 1);
        vm.prank(PRODUCER);
        vm.expectRevert("VaultFactoryFacet: vault has been destroyed");
        IVaultFactory.releaseVaultTokens(vaultId);
    }

    // Receipts cannot be burned on an already deployed timelock, so a vault
    // whose receipts have been split must not be destroyed - the fractional
    // owner would be left with a claim on tokens that no longer exist.
    function testRevertsWhenReceiptsWereTransferred() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        TokenTimelock timelock = TokenTimelock(
            IVaultFactory.getVaultLocationById(vaultId)
        );

        vm.prank(PRODUCER);
        timelock.transfer(OTHER_PRODUCER, 500000000);

        vm.expectRevert(
            "VaultFactory: vault receipts are not wholly held by the beneficiary"
        );
        IERC20Petro.destroyVaults(ids(vaultId));

        // Nothing was burned and the vault is still open.
        assertEq(IVaultFactory.getVaultBalanceById(vaultId), 19500000000);
        assertEq(IVaultFactory.getHolderVaults(PRODUCER).length, 1);
    }

    // One bad id in the batch rolls back the whole call.
    function testBatchIsAllOrNothing() public {
        uint256 good = mintTo(PRODUCER, 19500000000);
        uint256 supplyBefore = IERC20Petro.totalSupply();

        vm.expectRevert("VaultFactory: vault does not exist");
        IERC20Petro.destroyVaults(ids(good, 9999));

        assertEq(IERC20Petro.totalSupply(), supplyBefore);
        assertEq(IVaultFactory.getVaultBalanceById(good), 19500000000);
        assertFalse(IVaultFactory.isVaultDestroyed(good));
    }

    function testRevertsOnAlreadyDestroyedVault() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        IERC20Petro.destroyVaults(ids(vaultId));

        vm.expectRevert("VaultFactory: vault already destroyed");
        IERC20Petro.destroyVaults(ids(vaultId));
    }

    function testRevertsOnUnknownVault() public {
        vm.expectRevert("VaultFactory: vault does not exist");
        IERC20Petro.destroyVaults(ids(1));
    }

    function testOnlyOwnerCanDestroy() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);

        vm.prank(NOT_OWNER);
        vm.expectRevert();
        IERC20Petro.destroyVaults(ids(vaultId));
    }

    function testCannotDestroyWhilePaused() public {
        uint256 vaultId = mintTo(PRODUCER, 19500000000);
        IERC20Petro.pause();

        vm.expectRevert();
        IERC20Petro.destroyVaults(ids(vaultId));
    }
}

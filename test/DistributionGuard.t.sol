// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./TestStates.sol";
import "../script/DistributionGuard.sol";
import "../src/libraries/LibERC20Enhanced.sol";

// The guard is what stands between a partially broadcast mint script and a
// duplicate distribution, so it gets the same coverage as the facets do.
contract TestDistributionGuard is StateDeployDiamond, DistributionGuard {
    address constant PRODUCER_A = 0x55eb317fF962dE0c9753CF7bFADbbEF4aaa789c8;
    address constant PRODUCER_B = 0xCf3b547c78b92C1e5C1A05d622E655Dc6d18Fd6B;

    function plan()
        internal
        pure
        returns (address[] memory addresses, uint256[] memory amounts)
    {
        addresses = new address[](3);
        addresses[0] = PRODUCER_A;
        addresses[1] = PRODUCER_A;
        addresses[2] = PRODUCER_B;

        amounts = new uint256[](3);
        amounts[0] = 19500000000;
        amounts[1] = 2000000000;
        amounts[2] = 10500000000;
    }

    // enforceNoDuplicateVaults is internal, and vm.expectRevert latches onto the
    // next external call - which would otherwise be one of the guard's own view
    // reads. Going through this wrapper makes the guard itself the call under
    // test.
    function callGuard(
        address[] memory addresses,
        uint256[] memory amounts,
        bool allowDuplicates
    ) external view {
        enforceNoDuplicateVaults(
            IVaultFactory,
            addresses,
            amounts,
            allowDuplicates
        );
    }

    function mintPlanEntry(uint256 index) internal {
        (address[] memory addresses, uint256[] memory amounts) = plan();
        IERC20Petro.mintProducerTokens(
            addresses[index],
            amounts[index],
            1,
            LibErc20Enhanced.AssetCategory.Services
        );
    }

    // A clean chain has nothing to collide with, so the plan passes.
    function testPassesOnFirstRun() public view {
        (address[] memory addresses, uint256[] memory amounts) = plan();
        enforceNoDuplicateVaults(IVaultFactory, addresses, amounts, false);
    }

    // The exact failure from the incident: the run died after entries 0 and 1
    // were broadcast, and the whole script was launched again from the top.
    function testRevertsWhenPartialRunIsRepeated() public {
        mintPlanEntry(0);
        mintPlanEntry(1);

        (address[] memory addresses, uint256[] memory amounts) = plan();
        vm.expectRevert(
            "DistributionGuard: distribution already minted - resume the failed run instead of re-running it"
        );
        this.callGuard(addresses, amounts, false);
    }

    // A single already-minted entry is enough to stop the re-run.
    function testRevertsOnSingleExistingVault() public {
        mintPlanEntry(2);

        (address[] memory addresses, uint256[] memory amounts) = plan();
        vm.expectRevert(
            "DistributionGuard: distribution already minted - resume the failed run instead of re-running it"
        );
        this.callGuard(addresses, amounts, false);
    }

    // The override exists for recipients who really are owed a second vault of
    // an amount they already hold.
    function testAllowDuplicatesOverridesTheGuard() public {
        mintPlanEntry(0);

        (address[] memory addresses, uint256[] memory amounts) = plan();
        enforceNoDuplicateVaults(IVaultFactory, addresses, amounts, true);
    }

    // A vault held by someone else, or for a different amount, is not a
    // duplicate and must not block the run.
    function testUnrelatedVaultsDoNotTrip() public {
        IERC20Petro.mintProducerTokens(
            PRODUCER_A,
            777000000,
            1,
            LibErc20Enhanced.AssetCategory.Services
        );
        IERC20Petro.mintProducerTokens(
            address(this),
            19500000000,
            1,
            LibErc20Enhanced.AssetCategory.Services
        );

        (address[] memory addresses, uint256[] memory amounts) = plan();
        enforceNoDuplicateVaults(IVaultFactory, addresses, amounts, false);
    }

    // reportExistingVaults only reads, but it walks every vault of every
    // recipient and must survive both the empty and populated cases.
    function testReportExistingVaults() public {
        (address[] memory addresses, ) = plan();
        reportExistingVaults(IVaultFactory, addresses);

        mintPlanEntry(0);
        mintPlanEntry(2);
        reportExistingVaults(IVaultFactory, addresses);
    }
}

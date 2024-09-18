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

contract FullVaultAudit is Script, HelperContract {
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

    function run() external {
        vm.startBroadcast();
        IVaultFactory = VaultFactoryFacet(
            address(0xbaFff1fca61Eaad3726fcd88fbe128a852c2e2FA)
        );
        IERC20Petro = IErc20PetroCoin(
            address(0xbaFff1fca61Eaad3726fcd88fbe128a852c2e2FA)
        );

        console.log("Diamond Address:", address(IVaultFactory));

        console.log("number of vaults made:", IVaultFactory.vaultCount());
        console.log("total PTCN supply:", IERC20Petro.totalSupply());
        console.log(
            "total treasury minted",
            IERC20Petro.getMintedTreasuryTokens()
        );
        console.log("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
        for (uint256 i = 1; i <= IVaultFactory.vaultCount(); i++) {
            console.log("vaultId:", i);
            address vaultAddress = IVaultFactory.getVaultLocationById(i);
            console.log("Vault Address:", vaultAddress);
            uint256 releaseTime = IVaultFactory.getVaultReleaseTime(i);
            console.log("releaseTime:", releaseTime);
            address beneficiary = IVaultFactory.getVaultBeneficiary(i);
            console.log("beneficiary:", beneficiary);
            uint256 vaultBalance = IVaultFactory.getVaultBalanceById(i);
            console.log("vault balance:", vaultBalance);
            uint256 ptcnBalance = IERC20Petro.balanceOf(beneficiary);
            console.log("Beneficiary PTCN Balance:", ptcnBalance);
            console.log("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
            console.log(" ");
        }
        vm.stopBroadcast();
    }
}

contract ReleaseVaultToken is Script, HelperContract {
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
    function run() external {
        vm.startBroadcast();
        IVaultFactory = VaultFactoryFacet(
            address(0xbaFff1fca61Eaad3726fcd88fbe128a852c2e2FA)
        );
        address beneficiaryToRelease = address(
            0x993A040a022fB002f36E0Fb0831e5DB0050cFFcD
        );
        console.log("Releasing vaults for address:", beneficiaryToRelease);
        IVaultFactory.releaseVaultTokens(3);
        IERC20Petro = IErc20PetroCoin(
            address(0xbaFff1fca61Eaad3726fcd88fbe128a852c2e2FA)
        );
        uint256 ptcnBalance = IERC20Petro.balanceOf(beneficiaryToRelease);
        console.log("Beneficiary PTCN Balance:", ptcnBalance);

        // for (uint256 i = 1; i <= IVaultFactory.vaultCount(); i++) {
        //     console.log("Attempting to release vault tokens for vaultId:", i);
        //     console.log("Current Time is:", block.timestamp);
        //     console.log(
        //         "Release Time is:",
        //         IVaultFactory.getVaultReleaseTime(i)
        //     );
        //     try IVaultFactory.releaseVaultTokens(i) {
        //         console.log("Vault Tokens Released for vaultId:", i);
        //     } catch (bytes memory reason) {
        //         console.log("Unable to release tokens for vaultId:", i);
        //         console.log(string(reason));
        //     }
        // }

        vm.stopBroadcast();
    }
}

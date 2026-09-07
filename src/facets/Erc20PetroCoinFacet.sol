// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/LibERC20Enhanced.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "./VaultFactoryFacet.sol";

contract Erc20PetroCoinFacet {
    event TokenDistribution(
        uint256 indexed tokensMinted,
        uint256 indexed estimatedValue,
        LibErc20Enhanced.AssetCategory indexed assetCategory
    );

    event TokenRedemption(
        uint256 indexed tokensBurned,
        uint256 indexed redeemedValue,
        LibErc20Enhanced.AssetCategory indexed assetCategory
    );

    event VaultDestroyed(
        uint256 indexed vaultId,
        address indexed holder,
        uint256 tokensBurned
    );

    function initErc20PetroCoin(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals,
        uint256 _longHoldPeriod,
        uint256 _producerHoldPeriod
    ) public {
        LibErc20Enhanced.ERC20Storage storage erc20Enhanced = LibErc20Enhanced
            .erc20Storage();
        require(!erc20Enhanced.initialized, "ALREADY_INITIALIZED");
        erc20Enhanced.name = _name;
        erc20Enhanced.symbol = _symbol;
        erc20Enhanced.totalSupply = _totalSupply;
        erc20Enhanced.initialized = true;
        erc20Enhanced.decimals = _decimals;
        erc20Enhanced.longHoldPeriod = _longHoldPeriod;
        erc20Enhanced.producerHoldPeriod = _producerHoldPeriod;
    }

    // ERC20 functions

    function name() public view returns (string memory) {
        return LibErc20Enhanced.name();
    }

    function symbol() public view returns (string memory) {
        return LibErc20Enhanced.symbol();
    }

    function decimals() public view returns (uint8) {
        return LibErc20Enhanced.decimals();
    }

    function totalSupply() public view returns (uint256) {
        return LibErc20Enhanced.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return LibErc20Enhanced.balanceOf(account);
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return LibErc20Enhanced.allowance(owner, spender);
    }

    function getLongHoldPeriod() public view returns (uint256) {
        return LibErc20Enhanced.longHoldPeriod();
    }

    function getProducerHoldPeriod() public view returns (uint256) {
        return LibErc20Enhanced.producerHoldPeriod();
    }
    function getMintedTreasuryTokens() public view returns (uint256) {
        return LibErc20Enhanced.treasurySupply();
    }

    function mintTreasuryTokens(
        address recipient,
        uint256 amount
    ) public returns (TokenTimelock timelock) {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced.enforceNotPaused();

        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[recipient].push(vaultId);

        timelock = new TokenTimelock(
            IERC20(address(this)),
            recipient,
            block.timestamp + LibErc20Enhanced.longHoldPeriod(),
            amount
        );
        es.vaultLocation[vaultId] = address(timelock);
        LibErc20Enhanced.mintTreasuryTokens(amount, address(timelock));
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        LibErc20Enhanced.enforceNotPaused();
        LibErc20Enhanced.transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        LibErc20Enhanced.enforceNotPaused();

        LibErc20Enhanced.transferFrom(owner, recipient, amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        LibErc20Enhanced.enforceNotPaused();

        LibErc20Enhanced.increaseAllowance(msg.sender, spender, addedValue);

        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        LibErc20Enhanced.enforceNotPaused();

        LibErc20Enhanced.decreaseAllowance(
            msg.sender,
            spender,
            subtractedValue
        );

        return true;
    }

    function setLongHoldPeriod(uint256 _longHoldPeriod) public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced.erc20Storage().longHoldPeriod = _longHoldPeriod;
    }

    function setProducerHoldPeriod(uint256 _producerHoldPeriod) public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced
            .erc20Storage()
            .producerHoldPeriod = _producerHoldPeriod;
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        LibErc20Enhanced.approve(msg.sender, spender, amount);
        return true;
    }

    function mintProducerTokens(
        address account,
        uint256 amount,
        uint256 estimatedValue,
        LibErc20Enhanced.AssetCategory assetCategory
    ) public returns (TokenTimelock timelock) {
        timelock = mintProducerTokens(account, amount);
        emit TokenDistribution(amount, estimatedValue, assetCategory);
    }

    function mintAdvisoryToken(
        address account,
        uint256 amount
    ) public returns (TokenTimelock timelock) {
        timelock = mintProducerTokens(account, amount);
    }

    function mintProducerTokens(
        address account,
        uint256 amount
    ) internal returns (TokenTimelock timelock) {
        LibErc20Enhanced.enforceNotPaused();
        LibDiamond.enforceIsContractOwner();
        uint256 producerHoldPeriod = LibErc20Enhanced.producerHoldPeriod();

        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[account].push(vaultId);

        timelock = new TokenTimelock(
            IERC20(address(this)),
            account,
            block.timestamp + producerHoldPeriod,
            amount
        );
        es.vaultLocation[vaultId] = address(timelock);

        LibErc20Enhanced.mint(amount, address(timelock));
    }

    function mintBackdatedProducerTokens(
        address account,
        uint256 amount,
        uint256 estimatedValue,
        uint256 newTokenLockPeriod,
        LibErc20Enhanced.AssetCategory assetCategory
    ) external returns (TokenTimelock timelock) {
        LibErc20Enhanced.enforceNotPaused();
        LibDiamond.enforceIsContractOwner();
        uint256 producerHoldPeriod = newTokenLockPeriod;

        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[account].push(vaultId);

        timelock = new TokenTimelock(
            IERC20(address(this)),
            account,
            block.timestamp + producerHoldPeriod,
            amount
        );
        es.vaultLocation[vaultId] = address(timelock);

        LibErc20Enhanced.mint(amount, address(timelock));
        emit TokenDistribution(amount, estimatedValue, assetCategory);
    }
    // Unwinds vaults that should never have existed - a mint sent to the wrong
    // account, or a distribution script that was re-run and minted twice. Burns
    // every PTCN the vault holds and drops it from the holder's open vaults, so
    // getHolderVaults and totalSupply both stop counting it.
    //
    // Takes an array so an entire bad distribution is undone in one transaction
    // rather than one fragile call per vault.
    //
    // This is deliberately not tokenRedemption: a redemption is a producer
    // exchanging tokens for value received, and routing mint errors through it
    // would corrupt that record.
    function destroyVaults(uint256[] calldata vaultIds) external {
        LibErc20Enhanced.enforceNotPaused();
        LibDiamond.enforceIsContractOwner();

        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        for (uint256 i = 0; i < vaultIds.length; i++) {
            uint256 vaultId = vaultIds[i];
            address vaultAddress = es.vaultLocation[vaultId];
            require(
                vaultAddress != address(0),
                "VaultFactory: vault does not exist"
            );
            require(
                !es.vaultDestroyed[vaultId],
                "VaultFactory: vault already destroyed"
            );

            TokenTimelock timelock = TokenTimelock(vaultAddress);
            address holder = timelock.initialBeneficiary();

            // Vault receipts are transferable, and an already deployed
            // TokenTimelock offers no way to burn them - release() is the only
            // path to _burn and it pays out the underlying tokens. So if the
            // receipts have been split among fractional owners, burning the
            // backing would leave them holding a claim on tokens that no longer
            // exist. Refuse unless the beneficiary still holds every receipt.
            require(
                timelock.balanceOf(holder) == timelock.totalSupply(),
                "VaultFactory: vault receipts are not wholly held by the beneficiary"
            );

            uint256 lockedTokens = LibErc20Enhanced.balanceOf(vaultAddress);
            if (lockedTokens > 0) {
                LibErc20Enhanced.burn(lockedTokens, vaultAddress);
            }

            LibVaultFactory._destroyVault(vaultId, holder);

            emit VaultDestroyed(vaultId, holder, lockedTokens);
        }
    }

    function pause() public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced.pause();
    }
    function unpause() public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced.unpause();
    }

    function isPaused() public view returns (bool) {
        return LibErc20Enhanced.erc20Storage().paused;
    }

    function tokenRedemption(
        address redeemingAccount,
        uint256 amount,
        uint256 redeemedValue,
        LibErc20Enhanced.AssetCategory assetCategory
    ) public {
        LibErc20Enhanced.enforceNotPaused();
        LibDiamond.enforceIsContractOwner();
        require(
            LibErc20Enhanced.balanceOf(redeemingAccount) >= amount,
            "ERC20: burn amount exceeds balance"
        );
        LibErc20Enhanced.burn(amount, redeemingAccount);
        emit TokenRedemption(amount, redeemedValue, assetCategory);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/LibERC20Enhanced.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "./VaultFactoryFacet.sol";

//TODO: transfer tokenLock creation from mintProducerTokens to the vault factory
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
        require(LibErc20Enhanced.balanceOf(msg.sender) >= amount);
        LibErc20Enhanced.approve(msg.sender, spender, amount);
        return true;
    }

    function mintProducerTokens(
        address account,
        uint256 amount,
        uint256 estimatedValue,
        LibErc20Enhanced.AssetCategory assetCategory
    ) public returns (TokenTimelock timelock) {
        mintProducerTokens(account, amount);
        emit TokenDistribution(amount, estimatedValue, assetCategory);
    }

    function mintProducerTokens(
        address account,
        uint256 amount
    ) internal returns (TokenTimelock timelock) {
        LibErc20Enhanced.enforceNotPaused();
        LibDiamond.enforceIsContractOwner();
        uint256 producerHoldPeriod = LibErc20Enhanced.producerHoldPeriod();
        // TokenTimelock timeVault = _createTokenTimelock(
        //     IERC20(address(this)),
        //     account,
        //     block.timestamp + producerHoldPeriod
        // );
        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[account].push(vaultId);
        //TODO: Use create2 for a erc20 transfer prior to vault creation and confirm vault balance in the contructor.
        timelock = new TokenTimelock(
            IERC20(address(this)),
            account,
            block.timestamp + producerHoldPeriod,
            amount
        );
        es.vaultLocation[vaultId] = address(timelock);

        LibErc20Enhanced.mint(amount, address(timelock));
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
    //burnTreasureryToken
    //          burns tokens from the treasury
}

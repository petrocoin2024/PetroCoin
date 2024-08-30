// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErc20Enhanced} from "../libraries/LibERC20Enhanced.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "./VaultFactoryFacet.sol";

contract Erc20PetroCoinFacet {
    //!force ownership to initialize
    function initErc20PetroCoin(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals,
        uint256 _ownerHoldPeriod,
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
        erc20Enhanced.balances[address(this)] = _totalSupply;
        erc20Enhanced.ownerHoldPeriod = _ownerHoldPeriod;
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

    function getOwnerHoldPeriod() public view returns (uint256) {
        return LibErc20Enhanced.ownerHoldPeriod();
    }

    function getProducerHoldPeriod() public view returns (uint256) {
        return LibErc20Enhanced.producerHoldPeriod();
    }

    function getTreasureryBalance() public view returns (uint256) {
        return LibErc20Enhanced.balanceOf(address(this));
    }
    function transferTreasuryTokens(
        address recipient,
        uint256 amount
    ) public returns (TokenTimelock timelock) {
        LibDiamond.enforceIsContractOwner();
        //!todo: check if this is the correct way to do this
        // TokenTimelock timeVault = _createTokenTimelock(
        //     LibErc20Enhanced,
        //     recipient,
        //     block.timestamp + LibErc20Enhanced.ownerHoldPeriod()
        // );

        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[recipient].push(vaultId);

        timelock = new TokenTimelock(
            IERC20(address(this)),
            recipient,
            block.timestamp + LibErc20Enhanced.ownerHoldPeriod()
        );
        es.vaultLocation[vaultId] = address(timelock);
        LibErc20Enhanced.transfer(address(this), address(timelock), amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        LibErc20Enhanced.transfer(msg.sender, recipient, amount);
        return true;
    }

    function setOwnerHoldPeriod(uint256 _ownerHoldPeriod) public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced.erc20Storage().ownerHoldPeriod = _ownerHoldPeriod;
    }

    function setProducerHoldPeriod(uint256 _producerHoldPeriod) public {
        LibDiamond.enforceIsContractOwner();
        LibErc20Enhanced
            .erc20Storage()
            .producerHoldPeriod = _producerHoldPeriod;
    }

    function mintProducerTokens(
        address account,
        uint256 amount
    ) public returns (TokenTimelock timelock) {
        LibDiamond.enforceIsMajorityApprover();
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

        timelock = new TokenTimelock(
            IERC20(address(this)),
            account,
            block.timestamp + producerHoldPeriod
        );
        es.vaultLocation[vaultId] = address(timelock);

        LibErc20Enhanced.mint(address(timelock), amount);
    }

    // function mint(address account, uint256 amount) public {
    //     LibErc20Enhanced.mint(account, amount);
    // }

    // Functions

    // mintProducerTokens
    //          sends a certain number of tokens to the producer who has signed over o&g rights
    //          these tokens come with a hold period equal to _producerHoldPeriod
    //          requires simple majority vote to approve
    //pause
    //          pauses all token transfers
    //          requires unanimous vote to approve
    //unpause
    //          unpauses all token transfers
    //          requires unanimous vote to approve
    //transferTreasuryTokens
    //          Requires address of recipient, number of tokens, and hold period
    //          requires simple majority vote to approve
    // transfer
    //          overrides ERC20 transfer function to include hold period
    //          checks if owner address is waiting on a hold period to expire
    //          if not, it sends tokens
    //          if so, it reverts
    //burnTreasureryToken
    //          burns tokens from the treasury
    //selfDestruct
    //Constructor
    //          send tokens to owner with _ownerHoldPeriod hold period
    //          -->7500000 going to each owner
    //          send tokens to contract treasurery
}

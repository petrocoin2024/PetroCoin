// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErc20Enhanced} from "../libraries/LibERC20Enhanced.sol";

contract Erc20PetroCoinFacet {
    //!force ownership to initialize
    function initErc20PetroCoin(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimals
    ) public {
        LibErc20Enhanced.ERC20Storage storage erc20Enhanced = LibErc20Enhanced
            .erc20Storage();
        require(!erc20Enhanced.initialized, "ALREADY_INITIALIZED");
        erc20Enhanced.name = _name;
        erc20Enhanced.symbol = _symbol;
        erc20Enhanced.totalSupply = _totalSupply;
        erc20Enhanced.initialized = true;
        erc20Enhanced.decimals = _decimals;
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

    //State Variables
    //_treasuryDistrubtionHoldLedger
    //address -> _addressHoldPeriod
    //_mintDistruibutionHoldLedger
    //address -> _addressHoldPeriod
    // Functions
    // setOwnerHoldPeriod
    // Requires unanimous vote to approve
    // setProducerHoldPeriod
    // Requires unanimous vote to approve
    // setVotingApprovalThreshold
    // Requires unanimous vote to approve
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

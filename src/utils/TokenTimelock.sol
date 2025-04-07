pragma solidity ^0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";

contract TokenTimelock {
    IERC20 public immutable _token;
    address public _beneficiary;
    uint256 public immutable _releaseTime;

    mapping(address => uint256) public distributedShares;
    address[] public fractionalOwners;
    //add RELEASED bool

    constructor(IERC20 token_, address beneficiary_, uint256 releaseTime_) {
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function release() public {
        require(
            block.timestamp >= _releaseTime,
            "TokenTimelock: current time is before release time"
        );

        uint256 vaultBalance = _token.balanceOf(address(this));
        require(vaultBalance > 0, "TokenTimelock: no tokens to release");
        for (uint256 i = 0; i < fractionalOwners.length; i++) {
            vaultBalance -= distributedShares[fractionalOwners[i]];
            _token.transfer(
                fractionalOwners[i],
                distributedShares[fractionalOwners[i]]
            );
        }
        _token.transfer(_beneficiary, vaultBalance);
    }

    function transferBeneficiary(address newBeneficiary) public {
        require(
            msg.sender == _beneficiary,
            "TokenTimelock: only beneficiary can transfer"
        );
        _beneficiary = newBeneficiary;
    }

    function transferFractionalOwnership(
        address newBeneficiary,
        uint256 amount
    ) public {
        require(
            msg.sender == _beneficiary,
            "TokenTimelock: only beneficiary can transfer"
        );
        uint256 sharesCurrentlyOwnedByBeneficiary = _token.balanceOf(
            address(this)
        );
        bool newBeneficiaryExists = false;
        for (uint256 i = 0; i < fractionalOwners.length; i++) {
            sharesCurrentlyOwnedByBeneficiary -= distributedShares[
                fractionalOwners[i]
            ];
            if (fractionalOwners[i] == newBeneficiary) {
                newBeneficiaryExists = true;
            }
        }
        require(
            sharesCurrentlyOwnedByBeneficiary >= amount,
            "TokenTimelock: insufficient shares owned by beneficiary"
        );

        distributedShares[newBeneficiary] += amount;
        if (!newBeneficiaryExists) {
            fractionalOwners.push(newBeneficiary);
        }
    }

    function returnFractionalOwnership(
        uint256 amount
    ) public returns (uint remainingShares) {
        require(
            distributedShares[msg.sender] != 0,
            "TokenTimelock: Only fractional owners can return shares"
        );
        require(
            distributedShares[msg.sender] >= amount,
            "TokenTimelock: insufficient shares"
        );
        distributedShares[msg.sender] -= amount;
        remainingShares = distributedShares[msg.sender];
    }
}

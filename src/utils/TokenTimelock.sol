pragma solidity ^0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";

contract TokenTimelock {
    IERC20 public immutable _token;
    address public immutable _beneficiary;
    uint256 public immutable _releaseTime;

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

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.transfer(_beneficiary, amount);
    }
}

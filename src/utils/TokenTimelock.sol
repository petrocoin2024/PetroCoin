pragma solidity ^0.8.26;

import {IERC20} from "../interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TokenTimelock is ERC20 {
    using Strings for uint256;
    IERC20 public immutable _token;
    uint256 public immutable _releaseTime;
    bool public _released;
    address public immutable _initialBeneficiary;

    //add RELEASED bool

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 valueLocked_
    )
        ERC20(
            string(
                abi.encodePacked(
                    "Petrocoin Vault Receipt - ",
                    releaseTime_.toString()
                )
            ),
            string(abi.encodePacked("rPTCN_", releaseTime_.toString()))
        )
    {
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _token = token_;
        _mint(beneficiary_, valueLocked_);
        _releaseTime = releaseTime_;
        _initialBeneficiary = beneficiary_;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function isReleased() public view returns (bool) {
        return _released;
    }

    function initialBeneficiary() public view returns (address) {
        return _initialBeneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function release() public returns (uint256 remainingSupply) {
        require(
            block.timestamp >= _releaseTime,
            "TokenTimelock: current time is before release time"
        );
        require(
            balanceOf(msg.sender) > 0,
            "TokenTimelock: only beneficiaries can release"
        );
        require(!_released, "TokenTimelock: tokens already released");
        uint256 msgSenderBalance = balanceOf(msg.sender);
        _burn(msg.sender, msgSenderBalance);
        _token.transfer(msg.sender, msgSenderBalance);
        if (totalSupply() == 0) {
            _released = true;
        }
        remainingSupply = totalSupply();
    }
}

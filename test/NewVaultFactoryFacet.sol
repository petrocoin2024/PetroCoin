// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {LibVaultFactory} from "../src/libraries/LibVaultFactory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
contract NewTokenTimelock is ERC20 {
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
        return 42424242;
    }

    function release(
        address beneficiary_
    ) public returns (uint256 remainingSupply) {
        require(
            block.timestamp >= _releaseTime,
            "TokenTimelock: current time is before release time"
        );
        require(
            balanceOf(beneficiary_) > 0,
            "TokenTimelock: only beneficiaries can release"
        );
        require(!_released, "TokenTimelock: tokens already released");
        uint256 msgSenderBalance = balanceOf(beneficiary_);
        _burn(beneficiary_, msgSenderBalance);
        _token.transfer(beneficiary_, msgSenderBalance);
        if (totalSupply() == 0) {
            _released = true;
        }
        remainingSupply = totalSupply();
    }

    function testingNewFunctionLogic() public pure returns (string memory) {
        return "new logic";
    }
}
contract VaultFactoryFacetV2 {
    function vaultCount() public view returns (uint256) {
        return LibVaultFactory._getVaultCount();
    }

    function getHolderVaults(
        address holder
    ) public view returns (uint256[] memory) {
        return LibVaultFactory._getHolderVaults(holder);
    }

    function getVaultLocationById(
        uint256 vaultId
    ) public view returns (address) {
        return LibVaultFactory._getVaultLocationById(vaultId);
    }

    function getVaultReleaseTime(
        uint256 vaultId
    ) public view returns (uint256) {
        return 42424242;
    }

    function getVaultBalanceById(
        uint256 vaultId
    ) public view returns (uint256) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.token().balanceOf(address(timelock));
    }

    function getVaultInitialBeneficiary(
        uint256 vaultId
    ) public view returns (address) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.initialBeneficiary();
    }

    function getVaultFractionalOwnerBalance(
        uint256 vaultId,
        address fractionalOwner
    ) public view returns (uint256 balance) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        balance = timelock.balanceOf(fractionalOwner);
    }

    function releaseVaultTokens(
        uint256 vaultId
    ) public returns (uint256 remainingSupply) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        remainingSupply = timelock.release(msg.sender);
    }

    function testingNewFunctionLogic() public pure returns (string memory) {
        return "new logic";
    }
}

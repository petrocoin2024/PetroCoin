// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {LibVaultFactory} from "../src/libraries/LibVaultFactory.sol";

contract NewTokenTimelock {
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
        return 42424242;
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

    function testingNewFunctionLogic() public pure returns (string memory) {
        return "new logic";
    }
}

contract VaultFactoryFacetV2 {
    //todo test as an internal function only
    function createTokenTimelock(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime
    ) public returns (NewTokenTimelock) {
        return _createTokenTimelock(token, beneficiary, releaseTime);
    }

    function _createTokenTimelock(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime
    ) internal returns (NewTokenTimelock) {
        LibVaultFactory.VaultFactoryStorage storage es = LibVaultFactory
            .vaultFactoryStorage();

        uint256 vaultId = es.vaultCount + 1;
        es.vaultCount = vaultId;
        es.holderVaults[beneficiary].push(vaultId);

        NewTokenTimelock timelock = new NewTokenTimelock(
            token,
            beneficiary,
            releaseTime
        );
        es.vaultLocation[vaultId] = address(timelock);

        return timelock;
    }

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
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.releaseTime();
    }

    function getVaultBalanceById(
        uint256 vaultId
    ) public view returns (uint256) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.token().balanceOf(address(timelock));
    }

    function getVaultBeneficiary(
        uint256 vaultId
    ) public view returns (address) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.beneficiary();
    }

    function releaseVaultTokens(uint256 vaultId) public {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        timelock.release();
    }

    function testingNewFunctionLogic(
        uint256 vaultId
    ) public view returns (string memory) {
        NewTokenTimelock timelock = NewTokenTimelock(
            LibVaultFactory._getVaultLocationById(vaultId)
        );
        return timelock.testingNewFunctionLogic();
    }
}

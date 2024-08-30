pragma solidity ^0.8.26;

library LibErc20Enhanced {
    bytes32 constant ERC20_STORAGE_POSITION =
        keccak256("petrocoin.diamond.ERC20.storage");

    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
        string symbol;
        uint8 decimals;
        bool initialized;
        uint256 ownerHoldPeriod;
        uint256 producerHoldPeriod;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function name() internal view returns (string memory) {
        return erc20Storage().name;
    }
    function symbol() internal view returns (string memory) {
        return erc20Storage().symbol;
    }
    function decimals() internal view returns (uint8) {
        return erc20Storage().decimals;
    }
    function totalSupply() internal view returns (uint256) {
        return erc20Storage().totalSupply;
    }
    function balanceOf(address account) internal view returns (uint256) {
        return erc20Storage().balances[account];
    }
    function ownerHoldPeriod() internal view returns (uint256) {
        return erc20Storage().ownerHoldPeriod;
    }
    function allowance(
        address owner,
        address spender
    ) internal view returns (uint256) {
        return erc20Storage().allowances[owner][spender];
    }

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = erc20Storage().balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        erc20Storage().balances[sender] = senderBalance - amount;
        erc20Storage().balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    //transfer
    //transferFrom
    //approve
    //increaseAllowance
    //decreaseAllowance
    //burn
    //burnFrom
    //mint
    //mintTo
    //pause
    //unpause
}

pragma solidity ^0.8.26;

library LibErc20Enhanced {
    bytes32 constant ERC20_STORAGE_POSITION =
        keccak256("petrocoin.diamond.ERC20.storage");

    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        uint256 treasurySupply;
        string name;
        string symbol;
        uint8 decimals;
        bool initialized;
        uint256 longHoldPeriod;
        uint256 producerHoldPeriod;
        bool paused;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Paused(address account, uint256 time);
    event Unpaused(address account, uint256 time);

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
    function treasurySupply() internal view returns (uint256) {
        return erc20Storage().treasurySupply;
    }
    function balanceOf(address account) internal view returns (uint256) {
        return erc20Storage().balances[account];
    }
    function longHoldPeriod() internal view returns (uint256) {
        return erc20Storage().longHoldPeriod;
    }

    function producerHoldPeriod() internal view returns (uint256) {
        return erc20Storage().producerHoldPeriod;
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

    function approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        erc20Storage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address owner,
        address receiver,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: transfer from the zero address");
        require(receiver != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = erc20Storage().balances[owner];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 currentAllowance = erc20Storage().allowances[owner][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );

        erc20Storage().balances[owner] = senderBalance - amount;
        erc20Storage().balances[receiver] += amount;
        unchecked {
            erc20Storage().allowances[owner][msg.sender] =
                currentAllowance -
                amount;
        }
        emit Transfer(owner, receiver, amount);
        emit Approval(
            owner,
            msg.sender,
            erc20Storage().allowances[owner][msg.sender]
        );
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        erc20Storage().totalSupply += amount;
        erc20Storage().balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    //todo confirm erasing treasury token
    function mintTreasuryTokens(uint256 amount, address recipient) internal {
        require(recipient != address(0), "ERC20: mint to the zero address");

        erc20Storage().totalSupply += amount;
        erc20Storage().balances[recipient] += amount;
        erc20Storage().treasurySupply += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function pause() internal {
        require(!erc20Storage().paused, "ERC20: paused");
        erc20Storage().paused = true;
        emit Paused(msg.sender, block.timestamp);
    }
    function unpause() internal {
        require(erc20Storage().paused, "ERC20: not paused");
        erc20Storage().paused = false;
        emit Unpaused(msg.sender, block.timestamp);
    }

    function enforceWhenPaused() internal view {
        bool paused = erc20Storage().paused;
        require(paused, "ERC20: not paused");
    }

    function enforceNotPaused() internal view {
        bool paused = erc20Storage().paused;
        require(!paused, "ERC20: paused");
    }
    function increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ERC20Storage storage es = erc20Storage();

        uint256 currentAllowance = es.allowances[owner][spender];
        uint256 newAllowance = currentAllowance + addedValue;

        es.allowances[owner][spender] = newAllowance;

        emit Approval(owner, spender, newAllowance);
    }

    function decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ERC20Storage storage es = erc20Storage();

        uint256 currentAllowance = es.allowances[owner][spender];

        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );

        uint256 newAllowance;
        unchecked {
            newAllowance = currentAllowance - subtractedValue;
        }

        es.allowances[owner][spender] = newAllowance;

        emit Approval(owner, spender, newAllowance);
    }
}

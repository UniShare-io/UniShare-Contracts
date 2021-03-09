// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import   './Abstract/ERC20Burnable.sol';
import   './Ownable/Ownable.sol';
import   './Operator/Operator.sol';


contract UniShare is ERC20Burnable, Operator {
    constructor() public ERC20('UniShare', 'UNS') {
        // Mints 1 Uni Share to contract creator for initial Uniswap oracle deployment.
        // Will be burned after oracle deployment
        _mint(msg.sender, 1 * 10**18);
    }

    /**
     * @notice Operator mints Uni Share to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of Uni Share to mint to
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);
        return balanceAfter >= balanceBefore;
    }

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}
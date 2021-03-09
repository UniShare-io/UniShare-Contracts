// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import   './Abstract/ERC20Burnable.sol';
import   './Ownable/Ownable.sol';
import   './Operator/Operator.sol';

contract UniBond is ERC20Burnable, Ownable, Operator {
    /**
     * @notice Constructs the Uni Bond ERC-20 contract.
     */
    constructor() public ERC20('UniBond', 'UNB') {}

    /**
     * @notice Operator mints uni bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of uni bonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import   './Abstract/ERC20Burnable.sol';
import   './Ownable/Ownable.sol';
import   './Operator/Operator.sol';


contract UniCash is ERC20Burnable, Operator {
    /**
     * @notice Constructs the Uni Cash ERC-20 contract.
     */
    constructor() public ERC20('UniCash', 'UNC') {
        // Mints 1 Uni Cash to contract creator for initial Uniswap oracle deployment.
        // Will be burned after oracle deployment
        _mint(msg.sender, 1 * 10**18);
    }

    //    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    //        super._beforeTokenTransfer(from, to, amount);
    //        require(
    //            to != operator(),
    //            "Unicash.cash: operator as a recipient is not allowed"
    //        );
    //    }

    /**
     * @notice Operator mints Uni cash to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of Uni cash to mint to
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
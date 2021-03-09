// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '../Interface/IDistributor.sol';
import '../Library/SafeMath.sol';
import '../Interface/IERC20.sol';
import '../Abstract/IRewardDistributionRecipient.sol';

contract InitialUNSDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 cashAmount);

    bool public once = true;

    IERC20 public share;
    IRewardDistributionRecipient public uncethLPPool;
    uint256 public uncethInitialBalance;
    IRewardDistributionRecipient public unsethLPPool;
    uint256 public unsethInitialBalance;

    constructor(
        IERC20 _share,
        IRewardDistributionRecipient _uncethLPPool,
        uint256 _uncethInitialBalance,
        IRewardDistributionRecipient _unsethLPPool,
        uint256 _unsethInitialBalance
    ) public {
        share = _share;
        uncethLPPool = _uncethLPPool;
        uncethInitialBalance = _uncethInitialBalance;
        unsethLPPool = _unsethLPPool;
        unsethInitialBalance = _unsethInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialShareDistributor: you cannot run this function twice'
        );

        share.transfer(address(uncethLPPool), uncethInitialBalance);
        uncethLPPool.notifyRewardAmount(uncethInitialBalance);
        emit Distributed(address(uncethLPPool), uncethInitialBalance);

        share.transfer(address(unsethLPPool), unsethInitialBalance);
        unsethLPPool.notifyRewardAmount(unsethInitialBalance);
        emit Distributed(address(unsethLPPool), unsethInitialBalance);

        once = false;
    }
}
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {IStrategy} from "@tokenized-strategy/interfaces/IStrategy.sol";

interface IStrategyInterface is IStrategy {
    function asset() external view returns (address);

    function balanceOfStake() external view returns (uint256 _amount);

    function uniFees(address, address) external view returns (uint24 fee);
}

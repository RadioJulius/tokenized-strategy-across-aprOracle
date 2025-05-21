// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {AprOracleBase} from "@periphery/AprOracle/AprOracleBase.sol";
import {IHubPool} from "../interfaces/IHubPool.sol";
import {IStaking} from "../interfaces/IStaking.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";

import {UniswapV3SwapSimulator, ISwapRouter} from "../libraries/UniswapV3SwapSimulator.sol";

contract StrategyAprOracle is AprOracleBase {
    address constant HUB_ADDRESS = 0xc186fA914353c44b2E33eBE05f21846F1048bEda;
    address constant STAKING_ADDRESS = 0x9040e41eF5E8b281535a96D9a48aCb8cfaBD9a48;
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant REWARD_TOKEN = 0x44108f0223A3C3028F5Fe7AEC7f9bb2E66beF82F;
    uint256 constant YEAR = 31536000;

    constructor() AprOracleBase("Across Lender APR Oracle", msg.sender) {}

    /**
     * @notice Will return the expected Apr of a strategy post a debt change.
     * @dev _delta is a signed integer so that it can also represent a debt
     * decrease.
     *
     * This should return the annual expected return at the current timestamp
     * represented as 1e18.
     *
     *      ie. 10% == 1e17
     *
     * _delta will be == 0 to get the current apr.
     *
     * This will potentially be called during non-view functions so gas
     * efficiency should be taken into account.
     *
     * @param _strategy The token to get the apr for.
     * @param _delta The difference in debt.
     * @return . The expected apr for the strategy represented as 1e18.
     */
    function aprAfterDebtChange(address _strategy, int256 _delta) external view override returns (uint256) {
        return (
            getHubPoolBaseAPR(IStrategyInterface(_strategy).asset(), _delta)
                + getRewarderAPR(_strategy, IStrategyInterface(_strategy).asset(), _delta)
        );
    }

    function getHubPoolBaseAPR(address _asset, int256 _delta) public view returns (uint256) {
        (,,, int256 utilizedReserves, uint256 liquidReserves, uint256 undistributedLpFees) =
            IHubPool(HUB_ADDRESS).pooledTokens(_asset);

        require(utilizedReserves >= 0, "utilizedReserves must be non-negative");
        uint256 totalReserves = liquidReserves + uint256(utilizedReserves);
        if (_delta < 0 && liquidReserves < uint256(-_delta)) {
            totalReserves = uint256(utilizedReserves);
        } else {
            if (_delta >= 0) {
                totalReserves = totalReserves + uint256(_delta);
            } else {
                totalReserves = totalReserves - uint256(-_delta);
            }
        }
        // Undistributed Fees are distributed at the fee rate per second, we extrapolate this for a year
        uint256 feesPerYear = (undistributedLpFees * IHubPool(HUB_ADDRESS).lpFeeRatePerSecond() * YEAR) / 1e18;

        return (1e18 * feesPerYear) / totalReserves;
    }

    function getRewarderAPR(address _strategy, address _asset, int256 _delta) public view returns (uint256) {
        uint256 yearOfEmissions;
        uint256 cumulativeBalance;
        {
            (address lp,,,,,) = IHubPool(HUB_ADDRESS).pooledTokens(_asset);
            (
                , //bool enabled
                uint256 baseEmissionRate, //uint256 lastUpdateTime
                , //uint256 maxMultiplier
                , //uint256 secondsToMaxMultiplier
                uint256 cumulativeStaked, //uint256 rewardPerTokenStored
                ,
            ) = IStaking(STAKING_ADDRESS).stakingTokens(lp);
            (cumulativeBalance,,,) = IStaking(STAKING_ADDRESS).getUserStake(lp, _strategy);
            if (_delta < 0 && cumulativeBalance < uint256(-_delta)) {
                cumulativeBalance = 0;
            } else {
                if (_delta >= 0) {
                    cumulativeBalance = cumulativeBalance + uint256(_delta);
                } else {
                    cumulativeBalance = cumulativeBalance - uint256(-_delta);
                }
            }

            yearOfEmissions = (baseEmissionRate * YEAR * 1e18 * cumulativeBalance) / cumulativeStaked;
        }
        uint256 _output = UniswapV3SwapSimulator.simulateExactInputSingle(
            ISwapRouter(UNISWAP_V3_ROUTER),
            ISwapRouter.ExactInputSingleParams({
                tokenIn: REWARD_TOKEN,
                tokenOut: _asset,
                fee: IStrategyInterface(_strategy).uniFees(REWARD_TOKEN, _asset),
                recipient: address(0),
                deadline: block.timestamp,
                amountIn: yearOfEmissions,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        return (1e18 * _output) / cumulativeBalance;
    }
}

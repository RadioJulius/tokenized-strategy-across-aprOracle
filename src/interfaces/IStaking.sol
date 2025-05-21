interface IStaking {
    function stake(address stakedToken, uint256 amount) external;
    function unstake(address stakedToken, uint256 amount) external;
    function withdrawReward(address stakedToken) external;
    function getUserStake(address stakedToken, address account)
        external
        view
        returns (
            uint256 cumulativeBalance,
            uint256 averageDepositTime,
            uint256 rewardsAccumulatedPerToken,
            uint256 rewardsOutstanding
        );
    function getOutstandingRewards(address stakedToken, address account) external view returns (uint256);
    function stakingTokens(address stakedToken)
        external
        view
        returns (
            bool enabled,
            uint256 baseEmissionRate,
            uint256 maxMultiplier,
            uint256 secondsToMaxMultiplier,
            uint256 cumulativeStaked,
            uint256 rewardPerTokenStored,
            uint256 lastUpdateTime
        );
}

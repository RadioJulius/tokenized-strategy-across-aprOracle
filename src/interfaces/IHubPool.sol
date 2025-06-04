pragma solidity ^0.8.18;

interface IHubPool {
    function addLiquidity(
        address l1Token,
        uint256 l1TokenAmount
    ) external payable;

    function removeLiquidity(
        address l1Token,
        uint256 lpTokenAmount,
        bool sendEth
    ) external;

    function pooledTokens(
        address l1Token
    )
        external
        view
        returns (
            address lpToken,
            bool isEnabled,
            uint32 lastLpFeeUpdate,
            int256 utilizedReserves,
            uint256 liquidReserves,
            uint256 undistributedLpFees
        );

    function exchangeRateCurrent(address l1Token) external returns (uint256);

    function lpFeeRatePerSecond() external view returns (uint256);
}

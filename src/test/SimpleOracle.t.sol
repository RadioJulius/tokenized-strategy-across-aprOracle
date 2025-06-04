pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import {Setup} from "./utils/Setup.sol";
import {Test} from "forge-std/Test.sol";

import {StrategyAprOracle} from "../periphery/StrategyAprOracle.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";

contract SimpleOracleTest is Test {
    StrategyAprOracle public oracle;
    IStrategyInterface public strategy;
    address public asset = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        address deployedStrategyAddress = 0x9861708f2ad2BD1ed8D4D12436C0d8EB1ED36f1c;
        strategy = IStrategyInterface(deployedStrategyAddress);
        vm.label(address(strategy), "Strategy");
        oracle = new StrategyAprOracle();
    }

    function testSimpleOracleCheck() public {
        // Check set up
        // TODO: Add checks for the setup

        uint256 currentApr = oracle.aprAfterDebtChange(address(strategy), 0);

        // Should be greater than 0 but likely less than 100%
        assertGt(currentApr, 0, "ZERO");
        assertLt(currentApr, 1e18, "+100%");

        console2.log("currentAPR:", currentApr);

        // log our sub-sources of APR too
        uint256 baseAPR = oracle.getHubPoolBaseAPR(asset, 0);
        console2.log("Base APR:", baseAPR);

        uint256 rewardsAPR = oracle.getRewarderAPR(address(strategy), asset, 0);
        console2.log("Rewards APR:", rewardsAPR);
    }

    function testSimpleOracleCheckWithDeltaPositive(int256 _delta) public {
        _delta = bound(_delta, 0, 1e24);
        uint256 currentApr = oracle.aprAfterDebtChange(address(strategy), 0);

        console2.log("currentAPR With No Delta: ", currentApr);

        uint256 newApr = oracle.aprAfterDebtChange(address(strategy), _delta);

        console2.log("newAPR: ", newApr);
        console2.log("delta value: ", _delta);

        assertLe(newApr, currentApr);
    }

    function testSimpleOracleCheckWithDeltaNegative(int256 _delta) public {
        int256 strategyBalance = int256(strategy.balanceOfStake());

        _delta = bound(_delta, -strategyBalance, 0);
        uint256 currentApr = oracle.aprAfterDebtChange(address(strategy), 0);

        console2.log("currentAPR With No Delta: ", currentApr);

        uint256 newApr = oracle.aprAfterDebtChange(address(strategy), _delta);

        console2.log("newAPR: ", newApr);
        console2.log("delta value: ", _delta);

        assertGe(newApr, currentApr);
    }
}

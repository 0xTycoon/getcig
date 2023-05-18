pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

import './libraries/UniswapV2OracleLibrary.sol';
import './libraries/UniswapV2Library.sol';

// Minified version of oracle.sol,
// This version only tracks the WETH price for CIG/WETH SLP.
//
// Original comment from the example:
// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period

contract CigOracle {
    using FixedPoint for *;
    uint32 public immutable PERIOD;
    IUniswapV2Pair public constant pair = IUniswapV2Pair(0x22b15c7Ee1186A7C7CFfB2D942e20Fc228F6E4Ed);
    uint    public price0CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;

    constructor(uint32 _period) public {
        PERIOD = _period;
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        (, , blockTimestampLast) = pair.getReserves();
    }

    function _ts() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }


    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function _cumulativePrice() internal view returns (uint price0Cumulative, uint32 currentTs) {
        currentTs = _ts();
        price0Cumulative = pair.price0CumulativeLast();
        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 lastTs) = pair.getReserves();
        if (lastTs != currentTs) {
            // subtraction overflow is desired
            uint32 timeElapsed = currentTs - lastTs;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
        }
    }

    function update() external returns(bool) {
        (uint price0Cumulative, , uint32 blockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) {
            return false;
        }
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price0CumulativeLast = price0Cumulative;
        blockTimestampLast = blockTimestamp;
        return true;
    }


    // note this will always return 0 before update has been called successfully for the first time.
    function consult(uint amountIn) external view returns (uint amountOut) {
        amountOut = price0Average.mul(amountIn).decode144();
    }
}


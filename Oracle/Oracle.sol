// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import  '../Epoch/Epoch.sol';
import  '../Library/FixedPoint.sol';
import  '../Library/SafeMath.sol';
import '../Library/UniswapV2Library.sol';
import '../Library/UniswapV2OracleLibrary.sol';

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleUNC is Epoch {
    using FixedPoint for *;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // uniswap
    address public weth_;
    address public unc_;
    address public uni_;
    address public token0UNC;
    address public token1UNC;
    address public token0UNI;
    address public token1UNI;
    IUniswapV2Pair public pairUNC;
    IUniswapV2Pair public pairUNI;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLastUNC;
    uint256 public price1CumulativeLastUNC;
    uint256 public price0CumulativeLastUNI;
    uint256 public price1CumulativeLastUNI;
    FixedPoint.uq112x112 public price0AverageUNC;
    FixedPoint.uq112x112 public price1AverageUNC;
    FixedPoint.uq112x112 public price0AverageUNI;
    FixedPoint.uq112x112 public price1AverageUNI;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _factory,
        address _tokenUNC,
        address _tokenUNI,
        address _tokenWETH,
        //uint256 _period,
        uint256 _startTime
    ) public Epoch(1 days, _startTime, 0) {
        IUniswapV2Pair _pairUNC = IUniswapV2Pair(
            UniswapV2Library.pairFor(_factory, _tokenUNC, _tokenWETH)
        );
        IUniswapV2Pair _pairUNI = IUniswapV2Pair(
            UniswapV2Library.pairFor(_factory, _tokenUNI, _tokenWETH)
        );
        weth_ = _tokenWETH;
        unc_ = _tokenUNC;
        uni_ = _tokenUNI;
        pairUNC = _pairUNC;
        pairUNI = _pairUNI;
        token0UNC = _pairUNC.token0();
        token1UNC = _pairUNC.token1();
        token0UNI = _pairUNI.token0();
        token1UNI = _pairUNI.token1();
        price0CumulativeLastUNC = _pairUNC.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLastUNC = _pairUNC.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        price0CumulativeLastUNI = _pairUNI.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLastUNI = _pairUNI.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0UNC;
        uint112 reserve1UNC;
        uint112 reserve0UNI;
        uint112 reserve1UNI;
        (reserve0UNC, reserve1UNC, blockTimestampLast) = _pairUNC.getReserves();
        (reserve0UNI, reserve1UNI, blockTimestampLast) = _pairUNI.getReserves();
        require(reserve0UNC != 0 && reserve1UNC != 0 && reserve0UNI != 0 && reserve1UNI != 0, 'Oracle: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() external checkEpoch {
        (
            uint256 price0CumulativeUNC,
            uint256 price1CumulativeUNC,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairUNC));
        (
            uint256 price0CumulativeUNI,
            uint256 price1CumulativeUNI,
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairUNI));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0AverageUNC = FixedPoint.uq112x112(
            uint224((price0CumulativeUNC - price0CumulativeLastUNC) / timeElapsed)
        );
        price1AverageUNC = FixedPoint.uq112x112(
            uint224((price1CumulativeUNC - price1CumulativeLastUNC) / timeElapsed)
        );
        price0AverageUNI = FixedPoint.uq112x112(
            uint224((price0CumulativeUNI - price0CumulativeLastUNI) / timeElapsed)
        );
        price1AverageUNI = FixedPoint.uq112x112(
            uint224((price1CumulativeUNI - price1CumulativeLastUNI) / timeElapsed)
        );

        price0CumulativeLastUNC = price0CumulativeUNC;
        price1CumulativeLastUNC = price1CumulativeUNC;
        price0CumulativeLastUNI = price0CumulativeUNI;
        price1CumulativeLastUNI = price1CumulativeUNI;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0CumulativeUNC, price1CumulativeUNC,price0CumulativeUNI, price1CumulativeUNI);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn) //INPUT UNC,OUTPUT UNI
        external
        view
        returns (uint144 amountOut)
    {
        require(token == unc_,"error input:only UNC");
        uint256 amountOutUNC;
        //first calc output WETH amountOut
        if(token == token0UNC){
            amountOutUNC = price0AverageUNC.mul(amountIn).decode144();
        } else {
            require(token== token1UNC,"INVALID_TOKEN");
            amountOutUNC = price1AverageUNC.mul(amountIn).decode144();
        }
        //amountOutUNC is UNC TO SWAP ETH amount
        //2nd cala input weth to swap UNI amount
        uint144 amountOut1=price0AverageUNI.mul(amountOutUNC).decode144();
        if(amountOut1>amountOutUNC){
            amountOut = amountOut1;
        } else{
            amountOut = price1AverageUNI.mul(amountOutUNC).decode144();
        }
        
    }
    // collaboration of update / consult
    function expectedPrice(address token, uint256 amountIn)
        external
        view
        returns (uint224 amountOut)
    {
        (
            uint256 eprice0CumulativeUNC,
            uint256 eprice1CumulativeUNC,
            uint32 eblockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairUNC));
        (
            uint256 eprice0CumulativeUNI,
            uint256 eprice1CumulativeUNI,
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairUNI));
        uint32 etimeElapsed = eblockTimestamp - blockTimestampLast; // overflow is desired


        FixedPoint.uq112x112 memory eprice0AverageUNC = FixedPoint.uq112x112(
            uint224((eprice0CumulativeUNC - price0CumulativeLastUNC) / etimeElapsed)
        );
        FixedPoint.uq112x112 memory eprice1AverageUNC = FixedPoint.uq112x112(
            uint224((eprice1CumulativeUNC - price1CumulativeLastUNC) / etimeElapsed)
        );
        FixedPoint.uq112x112 memory eprice0AverageUNI = FixedPoint.uq112x112(
            uint224((eprice0CumulativeUNI - price0CumulativeLastUNI) / etimeElapsed)
        );
        FixedPoint.uq112x112 memory eprice1AverageUNI = FixedPoint.uq112x112(
            uint224((eprice1CumulativeUNI - price1CumulativeLastUNI) / etimeElapsed)
        );

        uint256 eamountOutUNC;
        //first calc output WETH amountOut
        if(token == token0UNC){
            eamountOutUNC = eprice0AverageUNC.mul(amountIn).decode144();
        } else {
            require(token== token1UNC,"INVALID_TOKEN");
            eamountOutUNC = eprice1AverageUNC.mul(amountIn).decode144();
        }
        //amountOutUNC is UNC TO SWAP ETH amount
        //2nd cala input weth to swap UNI amount
        uint224 amountOut1=eprice0AverageUNI.mul(eamountOutUNC).decode144();
        if(amountOut1>eamountOutUNC){
            amountOut = amountOut1;
        } else{
            amountOut = eprice1AverageUNI.mul(eamountOutUNC).decode144();
        }
        return amountOut;
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) external pure returns (address lpt) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    event Updated(uint256 price0CumulativeLastUNC, uint256 price1CumulativeLastUNC, uint256 price0CumulativeLastUNI, uint256 price1CumulativeLastUNI);
}

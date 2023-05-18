// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;

/**
* getcig.eth
* version 0.2.0
*
* Send a small amount of ETH to getcig.eth and you will get
* some Cigarettes back.
*
* https://www.coingecko.com/en/coins/cigarette
*
* The contract will swap the ETH and send you the CIG.
* It uses an oracle to ensure the swap is not being tampered.
*
*/

import "hardhat/console.sol";

contract GetCig {
    address constant public weth          = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public cig           = 0xCB56b52316041A62B6b5D0583DcE4A8AE7a3C629;
    IV2Router constant public sushiRouter = IV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICigOracle public immutable oracle;
    IPair constant public pair =           IPair(0x22b15c7Ee1186A7C7CFfB2D942e20Fc228F6E4Ed);

    constructor(address _oracle) {
        IWETH(weth).approve(
            0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,
            type(uint256).max
        );
        oracle = ICigOracle(_oracle);
    }

    /**
    * @dev update will pay someone to update the oracle
    */
    function update() external {
        IERC20 cigToken = IERC20(cig);
        uint256 b1 = cigToken.balanceOf(address(this));
        ILockedLiquidity r = ILockedLiquidity(0xaeD1117F9C01672646964d093643F8974Bb752B4);
        r.harvest();
        oracle.update();
        uint256 b2 = cigToken.balanceOf(address(this));
        if (b2 > b1) {
            cigToken.transfer(msg.sender, b2 - b1); // forward any CIG reward
        }
    }

    function getStats(address _a) {
        // todo
    }

    /*
    * @dev getAmountOut returns how much you will get at current exchange rate
    *   accounting for fees, assuming reserves.
    */
    function getAmountOut(uint256 _amountIn) view internal returns(uint256) {
        (uint256 reserveIn, uint256 reserveOut, ) = pair.getReserves();
        uint amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }


    /**
    * @dev receive will catch any ETH and swap to CIG.
    *   updates the oracle first, then checks the oracle price. Will not swap
    *   if the
    */
    receive() external payable {
        require(msg.value > 0, "need ETH");
        oracle.update();
        uint256 quote = oracle.consult(msg.value);
        uint256 outMin = getAmountOut(msg.value);      // how much we will get at current reserves.
        uint256 tolerateMin = outMin - (outMin / 100); // tolerate %1 less
        require (
            quote >= tolerateMin,
            "quote is less than tolerateMin");         // don't swap

        IWETH(weth).deposit{value:msg.value}();        // wrap ETH to WETH
        address[] memory path;
        path = new address[](2);
        path[0] = weth;
        path[1] = address(cig);
        sushiRouter.swapExactTokensForTokens(         // do the swap
            msg.value,
            outMin,
            path,
            msg.sender,
            block.timestamp
        );
    }
}

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


interface ICigOracle {
    function consult(uint amountIn) external view returns (uint amountOut);
    function update() external returns(bool);
}

interface IOracle {
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function quote(address token) external view returns (uint256 price);
    function update() external returns(bool);
}

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
address to;    // where to send harvested CIG rewards to
uint256 amount;// max CIG that will be sent
uint256 period;// how many blocks required between calls
uint256 block;  // record of last block number when called
*/
interface ILockedLiquidity {
    function harvest() external;
    function stipends(address) external view returns(address to, uint256 amount, uint256 period, uint256 block);
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

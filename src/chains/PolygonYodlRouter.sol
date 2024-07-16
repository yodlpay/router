pragma solidity ^0.8.26;

import "../routers/YodlNativeRouter.sol";
import "../routers/YodlCurveRouter.sol";
import "../routers/YodlUniswapRouter.sol";

contract PolygonYodlRouter is YodlNativeRouter, YodlCurveRouter, YodlUniswapRouter {

    constructor(string memory _version, uint256 _baseFeeBps, address _feeTreasury, address _wrappedNativeToken)
    AbstractYodlRouter()
    YodlNativeRouter()
    YodlCurveRouter(0x2a426b3Bb4fa87488387545f15D01d81352732F9)
    YodlUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564) {
        version = _version;
        baseFeeBps = _baseFeeBps;
        feeTreasury = _feeTreasury;
        wrappedNativeToken = IWETH9(_wrappedNativeToken);
    }
}
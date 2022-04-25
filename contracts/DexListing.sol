// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OriginOwner.sol";
import "./DexPair.sol";

contract DexListing is OriginOwner {

    address immutable public uniswapV2Router;
    address immutable public wbnbPair;
    address immutable public busdPair;

    uint internal listingFeePercent = 0;
    uint internal listingDuration;
    uint internal listingStartAt =  0;

    bool internal listingFinished;

    constructor(
        uint listingDuration_
    )
    {
        listingDuration = listingDuration_;
        //PancakeSwap: Router v2  // mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E  // testnet 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        address router = address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Router = router;
        wbnbPair = DexPair._createPair(router, DexPair.wbnb);
        busdPair = DexPair._createPair(router, DexPair.busd);
    }

    function _startListing()
    private
    onlyOriginOwner
    {
        listingStartAt = block.timestamp;
        listingFeePercent = 100;

        //Owner removed, once listing started
        _removeOriginOwner();
    }

    function _finishListing()
    private
    {
        listingFinished = true;
    }

    function _updateListingFee()
    private
    {
        uint pastTime = block.timestamp - listingStartAt; 
        if (pastTime > listingDuration) {
            listingFeePercent = 0;
        } else {
            // pastTime == 0 => fee = 100
            // pastTime == _listingDuration => fee = 0

            // listingDuration
            listingFeePercent = 100 * (listingDuration - pastTime) / listingDuration;
        }
    }

    function _updateAndGetListingFee(
        address sender_,
        address recipient_,
        uint256 amount_
    )
    internal
    returns (uint)
    {
        if (listingStartAt == 0) { 
            // first addLiquidity
            if (DexPair._isPair(recipient_) && amount_ > 0) {
                _startListing();
            }
            return 0;
        } else {
            _updateListingFee();
            if (listingStartAt + listingDuration <= block.timestamp) {
                _finishListing();
            }

            if (!DexPair._isPair(sender_) && !DexPair._isPair(recipient_)) { 
                // normal transfer  
                return 0;
            } else {
                // swap
                return amount_ * listingFeePercent / 100;
            }
        }
    }

    function getListingDuration()
    external
    view
    returns (uint)
    {
        return listingDuration;
    }

    function isListingFinished()
    external
    view
    returns (bool)
    {
        return listingFinished;
    }

    function listingStartAtBlock()
    external
    view
    returns (uint)
    {
        return listingStartAt;
    }

}
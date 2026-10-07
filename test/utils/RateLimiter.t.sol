// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RateLimiter} from "@openzeppelin/contracts/utils/RateLimiter.sol";

contract RateLimiterTest is Test {
    using RateLimiter for RateLimiter.RefillingBucket;

    RateLimiter.RefillingBucket internal _bucket;

    function testFuzzRefillingBucketNeverExceedsRefill(
        uint48 window,
        uint208 capacity,
        uint32[16] calldata delays,
        uint256[16] calldata quantities
    ) external {
        window = uint48(bound(window, 1, 365 days));
        capacity = uint208(bound(capacity, 1, type(uint128).max));
        _bucket.updateSettings(window, capacity);

        // Exact model of the bucket, tracking the used quantity scaled by `window` to avoid rounding.
        uint256 scaledUsed = 0;

        for (uint256 i = 0; i < delays.length; ++i) {
            uint256 delay = bound(delays[i], 0, 2 * uint256(window));
            vm.warp(block.timestamp + delay);
            scaledUsed = Math.saturatingSub(scaledUsed, delay * capacity);

            uint256 exactAvailable = (uint256(capacity) * window - scaledUsed) / window;
            assertLe(_bucket.available(0), exactAvailable);

            uint256 quantity = bound(quantities[i], 1, capacity);
            if (_bucket.tryConsume(0, quantity)) {
                assertLe(quantity, exactAvailable);
                scaledUsed += quantity * window;
            }
        }
    }
}

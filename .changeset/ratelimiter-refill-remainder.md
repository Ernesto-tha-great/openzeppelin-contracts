---
'openzeppelin-solidity': patch
---

`RateLimiter`: `RefillingBucket` no longer discards a partially refilled unit when a key is consumed before it has fully refilled. Buckets that refill slower than one unit per second now sustain their configured `capacity / window` rate.

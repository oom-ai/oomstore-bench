#!/usr/bin/env python3
import asyncio
import time
from oomclient import Client
import numpy as np


async def main():
    client = await Client.with_embedded_oomagent()
    features = [f"group_100.feature_{i}" for i in range(1, 101)]
    n = 10000
    durations = []
    for i in range(n):
        t = time.time()
        await client.online_get(str(i), features)
        durations.append((time.time() - t) * 1000)

    total_time = sum(durations)
    tpq = total_time / n
    print("latency: " + str(tpq) + "ms")

    arr = np.array(durations)
    p95 = np.percentile(arr, 95)
    p99 = np.percentile(arr, 99)
    print("p99: " + str(p99) + "ms")
    print("p95: " + str(p95) + "ms")


asyncio.run(main())

#!/usr/bin/env python3
import asyncio
import time
import sys
import random
import itertools
from oomclient import Client
import numpy as np


# python3 online_get.py <config> <requests> <concurrency> <max_key> <feature_count>
async def main():
    cfg_path = sys.argv[1]
    requests = int(sys.argv[2])
    concurrency = int(sys.argv[3])
    key_space = int(sys.argv[4])
    feature_count = int(sys.argv[5])
    client = await Client.with_embedded_oomagent(cfg_path=cfg_path)
    group = f"group_{feature_count}"
    await bench(client, requests, concurrency, key_space, group)


async def bench(client, requests, concurrency, key_space, features):
    tasks = [work(client, requests // concurrency, key_space, features) for _ in range(concurrency)]
    durations = list(itertools.chain(*await asyncio.gather(*tasks)))

    avg = np.average(durations)
    print(f"QPS: {1000 / avg * concurrency:.2f}")
    print(f"Avg: {avg:.2f}ms")
    print(f"Min: {np.min(durations):.2f}ms")
    print(f"Max: {np.max(durations):.2f}ms")
    print(f"Med: {np.median(durations):.2f}ms")
    print(f"P95: {np.percentile(durations, 95):.2f}ms")
    print(f"P99: {np.percentile(durations, 99):.2f}ms")


async def work(client, requests, key_space, group):
    durations = []
    for _ in range(requests):
        t = time.time()
        await client.online_get(str(random.randint(1, key_space)), group=group)
        durations.append((time.time() - t) * 1000)
    return durations


if __name__ == "__main__":
    asyncio.run(main())

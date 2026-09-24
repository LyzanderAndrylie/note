# Thundering Herd Problem (Cache Stampede)

The **Thundering Herd Problem** (also commonly referred to as a **Cache Stampede** or **Dog-piling**) is a system design concurrency issue that occurs when **a large number of incoming requests attempt to access an expired or missing cached resource simultaneously, overwhelming the backend database or downstream service**.

Under normal circumstances, caching layers like **Redis** absorb the vast majority of read traffic (e.g., 99%+ hit rate). However, the moment a hot cache key expires or is invalidated, all concurrent client requests experience a simultaneous **cache miss**. Each request then attempts to fetch the data from the underlying primary database and re-populate the cache at the exact same moment, causing a severe traffic spike that can bring down the database.

---

## 1. How It Happens

```mermaid
flowchart LR
    subgraph Clients ["Concurrent Traffic"]
        C1["Client 1"]
        C2["Client 2"]
        C3["Client 3"]
        C10k["... 10,000 Clients"]
    end

    subgraph CachingLayer ["Redis Cache Layer"]
        Cache[("Redis Cache<br/>Key: <code>product:123</code><br/><b>STATUS: EXPIRED ⏳</b>")]
    end

    subgraph PrimaryDB ["Primary Database"]
        DB[("PostgreSQL / MySQL<br/><b>Hit by 10,000 Queries! 💣</b>")]
    end

    subgraph ImpactArea ["System Impact 💥"]
        direction TB
        I1["❌ Massive Database CPU / RAM Spike"]
        I2["❌ Connection Pool Exhaustion"]
        I3["❌ Response Latency Spikes"]
        I4["❌ Request Timeouts (HTTP 504)"]
        I5["❌ Cascading Service Failures"]
    end

    Clients -->|"1. Concurrent Requests"| Cache
    Cache -->|"2. Cache MISS"| PrimaryDB
    PrimaryDB --> ImpactArea

    style CachingLayer fill:#fff1f0,stroke:#cf1322,stroke-width:2px
    style PrimaryDB fill:#fff2e8,stroke:#d4380d,stroke-width:2px
    style ImpactArea fill:#fffbe6,stroke:#d48806,stroke-width:1.5px
```

### The Breakdown Sequence

1. **Hot Key Expiration**: A frequently accessed item (e.g., a top-selling product on an e-commerce landing page) has a Time-To-Live (TTL) that reaches zero.
2. **Synchronized Cache Misses**: Thousands of incoming requests arrive in the same 50–100 millisecond window and query Redis for the key, receiving a `nil` (cache miss).
3. **Redundant Expensive Queries**: Instead of a single query refreshing the cache, all 10,000 requests execute identical, expensive SQL queries against the primary database concurrently.
4. **Backend Saturation**: The database runs out of available connection slots (see [PostgreSQL Connection Pooling](<file:///c:/Users/Lyzander%20Andrylie/Documents/(5)%20Note/software-engineer/concept/postgres/connection_pool.md>)), CPU utilization surges to 100%, and query execution times balloon from 5ms to several seconds.
5. **Cascading Failure**: Upstream API gateways and application threads reach timeout thresholds, causing request queues to back up and triggering wide-scale service outages.

---

## 2. Example Scenario & Lifecycle Timeline

Consider an e-commerce platform during high-traffic hours featuring a popular flash-sale product (`product:123`):

```mermaid
sequenceDiagram
    autonumber
    participant Users as 10,000 Concurrent Clients
    participant App as Application Servers
    participant Redis as Redis Cache
    participant DB as Primary Database

    Note over Users,DB: t0: Normal State (Cache Warm)
    Users->>App: GET /products/123
    App->>Redis: GET product:123
    Redis-->>App: Return cached JSON (Fast, <1ms)
    App-->>Users: 200 OK (Requests are fast)

    Note over Redis: t1: Key TTL expires (Key evicted)

    Note over Users,DB: t1 → t2: The Thundering Herd
    Users->>App: 10,000 clients request /products/123 simultaneously
    App->>Redis: 10,000 × GET product:123
    Redis-->>App: 10,000 × (nil / Cache Miss)

    Note over App,DB: All 10,000 app threads fall back to DB
    App->>DB: 10,000 × SELECT * FROM products WHERE id = 123
    Note over DB: t2: Database connection pool exhausted!<br/>CPU at 100%, slow queries or crashes 💣
    DB-->>App: Delayed responses / Connection timeouts / 500 errors
    App-->>Users: Slow responses (several seconds) or HTTP 504 Timeouts 😞

    Note over Users,DB: t3: Recovery & Repopulation
    App->>Redis: SET product:123 <json_data> EX 300
    Note over Users,DB: System slowly recovers as cache is warm again 😊
```

### Timeline Milestones

| Timestamp | Cache Status                | Database State                      | User Experience                                     |
| :-------- | :-------------------------- | :---------------------------------- | :-------------------------------------------------- |
| **$t_0$** | **Warm** (Cache Hit)        | Normal baseline load                | Instant sub-millisecond responses.                  |
| **$t_1$** | **Expired** (TTL reaches 0) | Calm before the storm               | Traffic continues flowing normally.                 |
| **$t_2$** | **Massive Misses**          | **Overloaded** (10K queries hit DB) | High latency, connection timeouts, HTTP 504 errors. |
| **$t_3$** | **Re-warmed** (Repopulated) | Load normalizes                     | System recovers; requests served from cache again.  |

---

## 3. How to Prevent & Mitigate

There are four primary architectural solutions to eliminate or mitigate the thundering herd problem:

```mermaid
flowchart TD
    Root["Thundering Herd Mitigation Strategies"]

    Root --> M1["1. Cache Warming<br/>(Proactive Pre-refresh)"]
    Root --> M2["2. Stale-While-Revalidate<br/>(Background Async Refresh)"]
    Root --> M3["3. Request Coalescing<br/>(Singleflight / Mutex Lock)"]
    Root --> M4["4. TTL Jitter<br/>(Randomized Expiration)"]

    style M1 fill:#e6f7ff,stroke:#1890ff,stroke-width:1.5px
    style M2 fill:#f6ffed,stroke:#52c41a,stroke-width:1.5px
    style M3 fill:#fff7e6,stroke:#fa8c16,stroke-width:1.5px
    style M4 fill:#f9f0ff,stroke:#722ed1,stroke-width:1.5px
```

---

### Strategy 1: Cache Warming (Proactive Refresh)

Instead of waiting for user traffic to experience a cache miss, an automated background job or scheduled cron periodically regenerates popular/hot keys **before** their TTL runs out.

```mermaid
flowchart LR
    Job["Background Worker / Cron Job ⏱️"] -->|"1. Fetch updated data"| DB[("Primary Database")]
    DB -->|"2. Return fresh data"| Job
    Job -->|"3. Pre-populate before TTL expires"| Redis[("Redis Cache")]
    Client["Client Traffic 👥"] -->|"Always hits warm cache!"| Redis

    style Job fill:#e6f7ff,stroke:#1890ff,stroke-width:1.5px
    style Redis fill:#f6ffed,stroke:#52c41a,stroke-width:1.5px
```

- **Mechanism**: Identify "hot keys" (e.g., homepage banners, top 100 products, exchange rates) and set up a background scheduler (e.g., Celery, temporal, or cron) that executes every $N$ minutes to refresh the cache.
- **Benefits**: End users **never** experience a cache miss for critical resources.
- **Trade-offs**: Only practical for predictable, finite sets of hot keys. You cannot warm millions of unique long-tail keys.

---

### Strategy 2: Stale-While-Revalidate (SWR) & Probabilistic Early Expiration

When a cache key expires, the application immediately serves the **slightly stale (old) data** to incoming users while triggering a **single asynchronous background task** to revalidate and update the cache.

```mermaid
sequenceDiagram
    autonumber
    actor User as Incoming User Request
    participant App as Application Server
    participant Redis as Redis Cache
    participant Worker as Background Goroutine / Task
    participant DB as Primary Database

    User->>App: GET /product:123
    App->>Redis: GET product:123
    Redis-->>App: Stale data + "is_expired=true" flag
    App-->>User: Return Stale Data Immediately (<1ms) 🚀

    Note over App,Worker: Asynchronously trigger background refresh
    App->>Worker: Dispatch revalidate job (async)
    Worker->>DB: 1 Query to Database
    DB-->>Worker: Fresh Data
    Worker->>Redis: SET product:123 <fresh_data>
```

#### Probabilistic Early Expiration (XFetch Algorithm)

Rather than using a hard TTL cutoff, the system computes the probability of refreshing the key on read requests before it actually expires:

$$\text{Probability to Refresh} = -\beta \times \delta \times \ln(\text{random}(0, 1)) > \text{Remaining TTL}$$

Where:

- $\delta$: The computation time required to fetch the data from the database.
- $\beta$: An aggressiveness multiplier ($> 0$, usually set to 1.0).
- As remaining TTL shrinks and read frequency increases, the likelihood that one client triggers an early background refresh approaches 100%, guaranteeing the cache never reaches absolute zero.

---

### Strategy 3: Request Coalescing (Singleflight / Mutex / Distributed Lock)

When a cache miss occurs across multiple concurrent requests, **only one request is permitted to call the database**. All other concurrent requests wait for that single in-flight query to finish and share the result.

```mermaid
sequenceDiagram
    autonumber
    actor C1 as Client 1 (Leader)
    actor C2 as Client 2 (Follower)
    actor C3 as Client 3 (Follower)
    participant App as App / Singleflight Group
    participant Redis as Redis
    participant DB as Database

    C1->>App: GET product:123
    C2->>App: GET product:123
    C3->>App: GET product:123

    App->>Redis: GET product:123 (Cache Miss)

    Note over App: Singleflight / Mutex: Only Client 1 executes DB query!<br/>Clients 2 & 3 await Client 1's channel/promise.

    App->>DB: 1 × SELECT * FROM products WHERE id = 123
    DB-->>App: Return record
    App->>Redis: SET product:123 <data> EX 300

    App-->>C1: Return Data
    App-->>C2: Return Same Shared Data
    App-->>C3: Return Same Shared Data
```

#### Implementation Options

1. **In-Memory Request Coalescing (Same Instance)**:
   - **Go**: `golang.org/x/sync/singleflight`
   - **Node.js**: Memoizing promises based on cache key.
   - **Java**: `ConcurrentHashMap` with `CompletableFuture`.
2. **Cross-Instance Coalescing via Redis Distributed Lock**:
   - When requests span multiple instances behind a load balancer, instances use a Redis mutex lock (`SET lock:key uuid NX EX 5`).
   - The instance that wins the lock executes the DB query and populates Redis.
   - Instances that fail to acquire the lock sleep briefly (e.g., 50ms) and retry reading the newly warmed cache.
   - _For in-depth details on implementing safe distributed locks, see [Distributed Locks with Redis](<file:///c:/Users/Lyzander%20Andrylie/Documents/(5)%20Note/software-engineer/concept/redis/lock.md>)._

---

### Strategy 4: Add Jitter to TTL (Randomized Expiration)

When caching thousands of records at the same time (e.g., bulk database exports, daily catalogs, or batch warming jobs), setting a static TTL (e.g., exactly 300 seconds) ensures they will all expire at the **exact same instant**, creating a synthetic thundering herd.

To avoid this, add random **jitter (entropy)** to the TTL:

$$\text{Actual TTL} = \text{Base TTL} + \text{Random}(0, \text{Jitter})$$

```mermaid
flowchart TD
    subgraph WithoutJitter ["❌ Static TTL (Synchronized Expiration Wave)"]
        direction LR
        K1["Key A: 300s"]
        K2["Key B: 300s"]
        K3["Key C: 300s"]
        K1 & K2 & K3 -->|"Expire at the exact same second!"| Spike["Massive DB Spike 💥"]
    end

    subgraph WithJitter ["✅ Jittered TTL (Staggered Expiration Wave)"]
        direction LR
        KJ1["Key A: 300s + 12s = 312s"]
        KJ2["Key B: 300s + 45s = 345s"]
        KJ3["Key C: 300s + 28s = 328s"]
        KJ1 & KJ2 & KJ3 -->|"Expirations spread out smoothly"| Smooth["Smooth, manageable DB Load 🟢"]
    end

    style WithoutJitter fill:#fff1f0,stroke:#cf1322,stroke-width:1.5px
    style WithJitter fill:#f6ffed,stroke:#52c41a,stroke-width:1.5px
```

#### Example Implementation

```python
import random

BASE_TTL = 300       # 5 minutes
MAX_JITTER = 60      # up to 1 minute extra

actual_ttl = BASE_TTL + random.randint(0, MAX_JITTER)
redis_client.set("product:123", serialized_data, ex=actual_ttl)
```

---

## 4. Comparison of Mitigation Strategies

| Strategy                   | Where Implemented        | Complexity  | Latency for User on Expiry                   | Best Used For                                                     |
| :------------------------- | :----------------------- | :---------- | :------------------------------------------- | :---------------------------------------------------------------- |
| **Cache Warming**          | Background Scheduler     | Low         | Zero latency impact (Cache never cold)       | Predictable hot resources (e.g., Top 50 products, homepage data)  |
| **Stale-While-Revalidate** | App / Cache Layer        | Medium      | Zero latency impact (Serves stale instantly) | Read-heavy endpoints where slight staleness (1–2s) is acceptable  |
| **Request Coalescing**     | App Layer / Redis Lock   | Medium–High | Minimal (One DB query time)                  | High-concurrency operations where fresh data is strictly required |
| **TTL Jitter**             | App Layer (Cache Writes) | Very Low    | Normal cache miss latency                    | Bulk/batch cached items and general baseline defense              |

---

## 5. Best Practices Checklist

```mermaid
mindmap
  root((Thundering Herd<br/>Best Practices))
    Key Management
      Add Jitter to all TTLs
      Separate TTL by volatility
      Never set static identical TTL on bulk inserts
    Concurrency Protection
      Implement Request Coalescing (Singleflight)
      Use Redis Distributed Locks for cross-instance coordination
    Data Serving
      Stale-While-Revalidate for non-critical reads
      Proactive Cache Warming for predictable hot keys
    Observability
      Monitor Cache Hit / Miss ratio
      Alert on DB connection pool saturation
      Track p95 and p99 query latency
```

- [x] **Always Add Jitter to TTLs**: Apply 10%–20% random entropy to avoid synchronized expiration waves.
- [x] **Use Cache Warming for Hot Keys**: Identify top traffic drivers and refresh them via background workers.
- [x] **Implement Request Coalescing**: Ensure only one in-flight database query occurs per unique missing key.
- [x] **Adopt Stale-While-Revalidate**: Return slightly stale data immediately while refreshing asynchronously in the background.
- [x] **Monitor Key Indicators**: Set up alerts for sudden drops in cache hit rate, spikes in DB connection pool usage, and database CPU threshold breaches.

---

## 6. Key Takeaways

1. **The Root Cause**: The thundering herd occurs when numerous requests hit the same resource at the exact same moment—typically right after cache expiry—overwhelming backend databases.
2. **Cascading Failure Risk**: Unmitigated cache stampedes can cascade from database exhaustion into API gateway timeouts and total system downtime.
3. **Layered Defense**: No single solution fits all keys:
   - Combine **TTL Jitter** as a universal baseline.
   - Use **Request Coalescing (Singleflight)** to guard against unexpected traffic spikes on cold keys.
   - Use **Cache Warming & SWR** for top tier hot keys.
4. **Massive ROI**: A small architectural adjustment (such as a singleflight mutex or TTL jitter) can prevent total database collapse during traffic peaks.

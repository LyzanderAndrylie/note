# DBOS Transact Go SDK

| Metadata      | Value                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------ |
| Author        | Lyzander Marciano Andrylie                                                                 |
| Creation Date | Nov 10, 2026                                                                               |
| Last Updated  | Nov 10, 2026                                                                               |
| Repositories  | [dbos-inc/dbos-transact-golang](https://github.com/dbos-inc/dbos-transact-golang) (v1.8.0) |

## References

- [DBOS Official Website](https://www.dbos.dev/): Overview of lightweight, database-backed durable workflow execution and transactional orchestration
- [DBOS Go Programming Guide](https://docs.dbos.dev/golang/programming-guide): Official guides covering Go workflows, steps, queues, messaging, scheduling, and upgrading
- [DBOS Go Package Reference](https://pkg.go.dev/github.com/dbos-inc/dbos-transact-golang/dbos): Go API documentation for `github.com/dbos-inc/dbos-transact-golang/dbos`
- [dbos.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/dbos.go): Lifecycle entry points (`NewContext`, `Launch`, `Shutdown`, `Config`, `RegisterWorkflow`, `RegisterQueue`)
- [workflow.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/workflow.go): Workflow execution (`RunWorkflow`), step wrappers (`RunAsStep`), handles (`WorkflowHandle`), messaging (`Send`, `Recv`), events (`SetEvent`, `GetEvent`), and streams
- [queue.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/queue.go): Database-backed durable queues, worker/global concurrency throttles, rate limiters, deduplication, and partition scheduling
- [datasource.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/datasource.go): Transactional application datasources (`DataSource`, `NewDataSource`, `RunAsTransaction`)
- [recovery.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/recovery.go): Startup crash recovery loop and deterministic step replay engine
- [scheduler.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/scheduler.go): Dynamic database-backed cron scheduling (`CreateSchedule`, `ApplySchedules`, `ScheduleSpec`)
- [mvcc.md](../../concept/data/postgres/mvcc.md): PostgreSQL Multi-Version Concurrency Control underlying DBOS transactional checkpoints and snapshot visibility
- [lock.md](../../concept/data/postgres/lock.md): PostgreSQL row-level locking and `FOR UPDATE SKIP LOCKED` semantics powering DBOS durable queues
- [connection_pool.md](../../concept/data/postgres/connection_pool.md): PostgreSQL connection pooling architecture managed via `pgxpool.Pool` in DBOS
- [outbox.md](../../concept/distributed-systems/outbox.md): Transactional outbox pattern achieved natively via DBOS workflows and `WithEnqueueTransaction`
- [dlq.md](../../concept/distributed-systems/dlq.md): Dead letter queue and poison-pill isolation patterns comparable to DBOS `MAX_RECOVERY_ATTEMPTS_EXCEEDED` and `ResumeWorkflow`
- [backpressure.md](../../concept/distributed-systems/backpressure.md): Producer-consumer flow control enforced via DBOS worker concurrency, global concurrency, and rate limiters

## Description

`github.com/dbos-inc/dbos-transact-golang/dbos` is an open-source, lightweight durable workflow execution and background task queue library for Go. Wrapping PostgreSQL/CockroachDB (`github.com/jackc/pgx/v5/pgxpool`) and SQLite (`database/sql`), it checkpoints workflow state and step outputs directly in a relational database so interrupted programs automatically resume from their last completed step without requiring external workflow clusters or message brokers. Backend engineers use it to build fault-tolerant payment pipelines, distributed sagas, rate-limited multi-tenant task queues, and long-running AI agent orchestrators.

### Runtime Bootstrap, Configuration, and Client Interface (`dbos/dbos.go`, `dbos/aliases.go`)

Initializes the DBOS execution context (`dbos.Context`) or a standalone external client (`dbos.Client`), validates or migrates the system database schema, and coordinates worker startup (`dbos.Launch`) and graceful drain (`dbos.Shutdown`).

- [dbos.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/dbos.go): Defines `Config`, `Context`, `Client`, `NewContext`, `NewClient`, `Launch`, `Shutdown`, and workflow/queue registration
- [aliases.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/aliases.go): Re-exports connection pool abstractions (`Pool`), transaction handles (`Tx`), SQL dialects (`DialectPostgres`, `DialectCockroach`, `DialectSQLite`), and isolation levels (`IsoLevelSerializable`, `IsoLevelRepeatableRead`, `IsoLevelReadCommitted`)

### Durable Workflow and Step Execution Engine (`dbos/workflow.go`, `dbos/serialization.go`, `dbos/errors.go`)

Executes generic `Workflow[P, R]` orchestrators and `Step[R]` functions, persisting workflow inputs/outputs in `dbos.workflow_status` and step outputs in `dbos.operation_outputs` for deterministic replay across process restarts.

- [workflow.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/workflow.go): Implements `RegisterWorkflow`, `RunWorkflow`, `RunAsStep`, `WorkflowHandle[R]`, `Send`/`Recv`, `SetEvent`/`GetEvent`, `WriteStream`/`ReadStream`, `Sleep`, `Patch`, and workflow management APIs
- [serialization.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/serialization.go): Provides generic `Serializer[T]` implementations (JSON and Gob) for encoding workflow arguments, step checkpoints, and event payloads
- [errors.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/errors.go): Defines typed sentinel errors (`ErrTimeout`, `ErrQueueDeduplicated`, `ErrWorkflowIDInUse`) and cross-language `PortableWorkflowError` wrappers

### Transactional Application DataSources (`dbos/datasource.go`, `dbos/datasource_migrations.go`)

Wraps user-managed application databases in a `DataSource` handle so workflow steps can execute application SQL queries and record execution checkpoints atomically within a single ACID database transaction (`RunAsTransaction`).

- [datasource.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/datasource.go): Defines `DataSource`, `NewDataSource`, `RunAsTransaction`, and `DataSourceOption` functions
- [datasource_migrations.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/datasource_migrations.go): Provisions the `transaction_completion` checkpoint table inside application schemas

### Database-Backed Workflow Queues and Throttling (`dbos/queue.go`)

Manages persistent background task queues in PostgreSQL/SQLite using `SELECT ... FOR UPDATE SKIP LOCKED`, enforcing per-worker concurrency, global concurrency, sliding-window rate limits, task deduplication, priority ordering, and per-tenant partition fairness.

- [queue.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/queue.go): Implements `Queue`, `RegisterQueue`, `RetrieveQueue`, `ListQueues`, `RateLimiter`, and worker polling loops

### Scheduling, Debouncing, and Durable Timers (`dbos/scheduler.go`, `dbos/debouncer.go`)

Coordinates time-based workflow triggers, including 6-field cron schedules backed by `dbos.workflow_schedules` and sliding-window request coalescing via `Debouncer`.

- [scheduler.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/scheduler.go): Implements `CreateSchedule`, `ApplySchedules`, `ScheduleSpec`, `ScheduledWorkflowInput`, and cron ticker loops
- [debouncer.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/debouncer.go): Implements `Debouncer` and `NewDebouncer` to coalesce rapid duplicate workflow invocations per key

### Crash Recovery, Schema Migrations, and Enterprise Conductor (`dbos/recovery.go`, `dbos/migrations.go`, `dbos/enterprise.go`)

Automates startup schema provisioning, recovers interrupted `PENDING` workflows matching the active `ApplicationVersion`, and connects to DBOS Conductor for distributed cluster observability.

- [recovery.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/recovery.go): Scans `dbos.workflow_status` on startup and replays interrupted workflows from their last checkpointed step
- [migrations.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/migrations.go): Executes embedded SQL migrations (`Migrate`) for the `dbos` system schema
- [enterprise.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/dbos/enterprise.go): Integrates worker telemetry and remote lifecycle commands with DBOS Conductor

### Command-Line Interface and Local Tooling (`cmd/dbos/`)

Provides the `dbos` CLI binary for project scaffolding, local Docker PostgreSQL management, standalone schema migrations, and live workflow inspection/control.

- [main.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/cmd/dbos/main.go): CLI entry point invoking the Cobra root command
- [workflow.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/cmd/dbos/workflow.go): Implements `dbos workflow list`, `get`, `steps`, `cancel`, `resume`, and `fork`
- [postgres.go](https://github.com/dbos-inc/dbos-transact-golang/blob/main/cmd/dbos/postgres.go): Implements `dbos postgres start` and `dbos postgres stop` for local Docker database provisioning

---

## Features

### 1. Context Lifecycle, System Database Architecture, and Client Bootstrap

DBOS operates embedded within the Go process, storing all workflow state, step checkpoints, queues, and messages in a dedicated relational schema (`dbos` by default) inside PostgreSQL, CockroachDB, or SQLite.

- **Two Execution Modes**:
  - **Full Workflow Runtime (`dbos.NewContext` + `dbos.Launch`)**: Initializes the system database connection pool (`*pgxpool.Pool` or `*sql.DB`), runs system migrations (unless `SkipMigrations: true`), starts background queue workers and cron schedulers, and recovers interrupted `PENDING` workflows matching `ApplicationVersion`.
  - **External Client (`dbos.NewClient`)**: Connects to the system database without starting worker goroutines or running migrations, enabling external HTTP gateways or CLI tools to enqueue workflows, send messages, read events, or query status.
- **Registration Order**: Workflows (`dbos.RegisterWorkflow`) must be registered **after** `dbos.NewContext` and **before** `dbos.Launch(ctx)`. Queues (`dbos.RegisterQueue`) and schedules (`dbos.CreateSchedule`) are database-backed and can be registered before or after launch.
- **Database Backends**:
  - **PostgreSQL / CockroachDB**: Production default using `jackc/pgx/v5/pgxpool` and `LISTEN/NOTIFY` for low-latency event delivery.
  - **SQLite**: Zero-setup local development and unit testing (`sqlite:app.db` or `sqlite::memory:`) enabled by importing `_ "github.com/dbos-inc/dbos-transact-golang/dbos/driver/sqlite"`.

#### `dbos.Config` Configuration Reference

| Field                | Type            | Default                   | Description                                                                                 |
| :------------------- | :-------------- | :------------------------ | :------------------------------------------------------------------------------------------ |
| `AppName`            | `string`        | _(Required)_              | Unique application identifier used to scope queues, schedules, and worker ownership         |
| `DatabaseURL`        | `string`        | `""`                      | System database DSN (`postgres://...` or `sqlite:...`); mutually exclusive with custom pool |
| `SystemDBPool`       | `*pgxpool.Pool` | `nil`                     | Custom pre-configured `pgx/v5` pool; takes precedence over `DatabaseURL`                    |
| `SQLiteSystemDB`     | `*sql.DB`       | `nil`                     | Custom SQLite `*sql.DB` handle; mutually exclusive with `SystemDBPool`                      |
| `DatabaseSchema`     | `string`        | `"dbos"`                  | PostgreSQL schema name storing DBOS control-plane tables                                    |
| `ApplicationVersion` | `string`        | `DBOS__APPVERSION` / hash | Version tag stamped onto workflows for safe rolling/blue-green recovery isolation           |
| `SkipMigrations`     | `bool`          | `false`                   | Verifies system schema existence on startup without executing DDL migrations                |
| `Logger`             | `*slog.Logger`  | `slog.Default()`          | Structured logger instance used by the DBOS runtime                                         |
| `ConductorURL`       | `string`        | `""`                      | Optional endpoint for DBOS Conductor observability and cluster management                   |
| `ConductorAPIKey`    | `string`        | `""`                      | Authentication key for DBOS Conductor                                                       |

#### Core System Database Tables (`dbos` Schema)

| Table                     | Primary Key                    | Role in Durable Execution                                                                               |
| :------------------------ | :----------------------------- | :------------------------------------------------------------------------------------------------------ |
| `dbos.workflow_status`    | `workflow_uuid`                | Tracks workflow lifecycle (`PENDING`, `ENQUEUED`, `SUCCESS`, `ERROR`, `CANCELLED`), inputs, and outputs |
| `dbos.operation_outputs`  | `(workflow_uuid, function_id)` | Stores step outputs, child workflow dispatches, and timer deadlines by sequential index                 |
| `dbos.workflow_queue`     | `name`                         | Persists queue concurrency limits, rate limiters, and polling configurations                            |
| `dbos.notifications`      | `message_uuid`                 | Stores durable FIFO messages per `(destination_uuid, topic)` for `Send` and `Recv`                      |
| `dbos.workflow_events`    | `(workflow_uuid, key)`         | Stores latest key-value state published via `SetEvent` (`workflow_events_history` for audit)            |
| `dbos.streams`            | `(workflow_uuid, key, seq)`    | Append-only log of stream chunks written via `WriteStream`                                              |
| `dbos.workflow_schedules` | `schedule_name`                | Persists dynamic 6-field cron definitions and last-fired timestamps                                     |

#### Interaction

```mermaid
sequenceDiagram
    participant Main as Go Application (main)
    participant DBOS as dbos.Context Runtime
    participant PG as PostgreSQL (dbos Schema)

    Main->>DBOS: dbos.NewContext(ctx, dbos.Config{AppName, DatabaseURL})
    DBOS->>PG: Initialize pgxpool.Pool
    Main->>DBOS: dbos.RegisterWorkflow(dbosCtx, myWorkflow)
    Main->>DBOS: dbos.Launch(dbosCtx)
    DBOS->>PG: Apply DDL migrations (dbos.dbos_migrations)
    DBOS->>PG: Establish persistent LISTEN connection
    DBOS->>PG: SELECT workflow_uuid FROM dbos.workflow_status WHERE status = 'PENDING' AND app_version = $1
    PG-->>DBOS: Interrupted workflow IDs
    DBOS->>DBOS: Spawn recovery goroutines & queue polling loops
    Main->>DBOS: defer dbos.Shutdown(dbosCtx, 5*time.Second)
```

#### Example

```go
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

func healthCheckWorkflow(ctx dbos.Context, serviceName string) (string, error) {
	return fmt.Sprintf("service %s is healthy", serviceName), nil
}

func main() {
	dbURL := os.Getenv("DBOS_SYSTEM_DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://postgres:dbos@localhost:5432/dbos_starter_go?sslmode=disable"
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))

	// 1. Initialize the DBOS Context
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:            "billing-orchestrator",
		ApplicationVersion: "1.0.0",
		DatabaseURL:        dbURL,
		DatabaseSchema:     "dbos",
		Logger:             logger,
	})
	if err != nil {
		panic(fmt.Sprintf("failed to initialize DBOS context: %v", err))
	}

	// 2. Register workflows prior to launching the runtime
	dbos.RegisterWorkflow(
		dbosCtx,
		healthCheckWorkflow,
		dbos.WithWorkflowName("healthCheckWorkflow"),
		dbos.WithMaxRecoveryAttempts(5),
	)

	// 3. Launch background workers, LISTEN/NOTIFY loops, and crash recovery
	if err := dbos.Launch(dbosCtx); err != nil {
		panic(fmt.Sprintf("failed to launch DBOS runtime: %v", err))
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	// 4. Invoke workflow synchronously via handle
	handle, err := dbos.RunWorkflow(dbosCtx, healthCheckWorkflow, "payments-api")
	if err != nil {
		panic(err)
	}

	out, err := handle.GetResult()
	if err != nil {
		panic(err)
	}
	fmt.Println(out)
}
```

---

### 2. Durable Workflows, Checkpointed Steps, and Exact-Once Transactions

DBOS separates deterministic orchestration logic (**Workflows**) from non-deterministic side effects (**Steps** and **Transactions**).

- **Workflow Signature (`dbos.Workflow[P, R]`)**: `func(ctx dbos.Context, input P) (R, error)` where `P` and `R` are serializable types. Workflows must be deterministic: branching, loops, and step invocations must depend only on `input` and returned step results.
- **Step Signature (`dbos.Step[R]`)**: `func(ctx context.Context) (R, error)`. Notice a step takes standard `context.Context` rather than `dbos.Context`, keeping step helper functions decoupled from DBOS primitives.
- **Step Execution (`dbos.RunAsStep`)**:
  - Assigns a monotonically increasing step index (`function_id = 0, 1, 2, ...`) within the workflow.
  - Before executing the function, DBOS checks `dbos.operation_outputs` for `(workflow_uuid, function_id)`. If a record exists (during recovery replay), DBOS skips executing the function and returns the stored output directly.
  - If the function is an anonymous closure, pass `dbos.WithStepName("explicitName")` so step identity remains stable across builds.
- **Child Workflows**: Calling `dbos.RunWorkflow(ctx, childWorkflow, input)` inside a parent workflow deterministically generates a child workflow ID (`"<parentID>-<functionID>"`) and checkpoints the dispatch in the parent's `operation_outputs`.

#### Workflow & Step Options Reference

| Scope            | Option Function                               | Description                                                                                                    |
| :--------------- | :-------------------------------------------- | :------------------------------------------------------------------------------------------------------------- |
| **Registration** | `WithWorkflowName(name string)`               | Overrides the default function-pointer reflection name                                                         |
| **Registration** | `WithMaxRecoveryAttempts(max int)`            | Caps crash recovery replays before marking `WorkflowStatusMaxRecoveryAttemptsExceeded`                         |
| **RunWorkflow**  | `WithWorkflowID(id string)`                   | Sets an explicit idempotency key for the workflow execution                                                    |
| **RunWorkflow**  | `WithWorkflowIDReusePolicy(policy)`           | `WorkflowIDReusePolicyReturnExisting` (default) or `WorkflowIDReusePolicyReject`                               |
| **RunWorkflow**  | `WithAuthenticatedUser(user string)`          | Records caller identity in `dbos.workflow_status` (`WithAuthenticatedRoles` for roles)                         |
| **RunAsStep**    | `WithStepName(name string)`                   | Sets a deterministic step identifier (mandatory for inline closures)                                           |
| **RunAsStep**    | `WithStepMaxRetries(maxRetries int)`          | Maximum retry attempts on transient error before failing the step                                              |
| **RunAsStep**    | `WithStepBaseInterval(d time.Duration)`       | Initial wait duration before the first retry                                                                   |
| **RunAsStep**    | `WithStepBackoffFactor(factor float64)`       | Exponential multiplier between retries: $\text{wait} = \text{base} \times \text{factor}^{n-1}$ (default `2.0`) |
| **RunAsStep**    | `WithStepMaxInterval(d time.Duration)`        | Upper bound capping exponential backoff wait duration                                                          |
| **RunAsStep**    | `WithStepRetryPredicate(fn func(error) bool)` | Inspects step error; retries only when predicate returns `true`                                                |

#### Interaction

```mermaid
sequenceDiagram
    participant Caller as HTTP Handler / Caller
    participant WF as Order Workflow (dbos.Context)
    participant SysDB as PostgreSQL (dbos Schema)
    participant API as External Payment API

    Caller->>SysDB: RunWorkflow(WithWorkflowID("ord-101")) -> INSERT workflow_status (PENDING)
    SysDB-->>WF: Start workflow execution (function_id = 0)
    WF->>SysDB: RunAsStep("chargeCard") -> Check operation_outputs (ord-101, fn_id=0)
    SysDB-->>WF: Not found (live execution)
    WF->>API: Charge credit card (49.99 USD)
    API-->>WF: Return tx_id = "ch_9981"
    WF->>SysDB: INSERT INTO operation_outputs (ord-101, fn_id=0, output="ch_9981")
    Note over WF,SysDB: Process crashes before Step 2! On restart, Recovery replays ord-101:
    WF->>SysDB: RunAsStep("chargeCard") -> Check operation_outputs (ord-101, fn_id=0)
    SysDB-->>WF: Found cached output "ch_9981" (Skip API call!)
    WF->>SysDB: Proceed to Step 2 (fn_id=1) & UPDATE workflow_status = 'SUCCESS'
```

#### a. Deterministic Replay, Retries, and Idempotency Keys

Passing `dbos.WithWorkflowID(idempotencyKey)` ensures that duplicate requests (such as webhook retries or double-clicked checkout buttons) never execute the workflow twice:

##### Example

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

type CheckoutInput struct {
	OrderID     string `json:"order_id"`
	AmountCents int    `json:"amount_cents"`
}

type CheckoutOutput struct {
	OrderID       string `json:"order_id"`
	ChargeID      string `json:"charge_id"`
	ReceiptNumber string `json:"receipt_number"`
}

var ErrCardDeclined = errors.New("card permanently declined")

func checkoutWorkflow(ctx dbos.Context, req CheckoutInput) (CheckoutOutput, error) {
	// Step 0: Charge payment gateway with exponential backoff retry policy
	chargeID, err := dbos.RunAsStep(
		ctx,
		func(stepCtx context.Context) (string, error) {
			return fmt.Sprintf("ch_%s_%d", req.OrderID, req.AmountCents), nil
		},
		dbos.WithStepName("chargePaymentGateway"),
		dbos.WithStepMaxRetries(4),
		dbos.WithStepBaseInterval(200*time.Millisecond),
		dbos.WithStepBackoffFactor(2.0),
		dbos.WithStepMaxInterval(5*time.Second),
		dbos.WithStepRetryPredicate(func(err error) bool {
			// Do not retry permanent card declines
			return !errors.Is(err, ErrCardDeclined)
		}),
	)
	if err != nil {
		return CheckoutOutput{}, err
	}

	// Step 1: Issue receipt
	receipt, err := dbos.RunAsStep(
		ctx,
		func(stepCtx context.Context) (string, error) {
			return fmt.Sprintf("RCPT-%s", req.OrderID), nil
		},
		dbos.WithStepName("issueReceipt"),
	)
	if err != nil {
		return CheckoutOutput{}, err
	}

	return CheckoutOutput{
		OrderID:       req.OrderID,
		ChargeID:      chargeID,
		ReceiptNumber: receipt,
	}, nil
}

func main() {
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:     "checkout-service",
		DatabaseURL: os.Getenv("DBOS_SYSTEM_DATABASE_URL"),
	})
	if err != nil {
		panic(err)
	}
	dbos.RegisterWorkflow(dbosCtx, checkoutWorkflow)
	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	input := CheckoutInput{OrderID: "ORD-500", AmountCents: 2999}

	// First call executes the workflow
	h1, err := dbos.RunWorkflow(
		dbosCtx,
		checkoutWorkflow,
		input,
		dbos.WithWorkflowID("idemp-ord-500"),
		dbos.WithWorkflowIDReusePolicy(dbos.WorkflowIDReusePolicyReturnExisting),
	)
	if err != nil {
		panic(err)
	}

	// Duplicate call with the same WorkflowID returns the existing execution handle
	h2, err := dbos.RunWorkflow(
		dbosCtx,
		checkoutWorkflow,
		input,
		dbos.WithWorkflowID("idemp-ord-500"),
	)
	if err != nil {
		panic(err)
	}

	res1, _ := h1.GetResult()
	res2, _ := h2.GetResult()
	fmt.Printf("Match: %v (ChargeID: %s)\n", res1.ChargeID == res2.ChargeID, res1.ChargeID)
}
```

#### b. Atomic Application Transactions via `DataSource` and `RunAsTransaction`

While `RunAsStep` offers **at-least-once** execution (if the process crashes after the external side effect succeeds but before the checkpoint commits to `dbos.operation_outputs`, the step re-runs on recovery), `dbos.RunAsTransaction` provides **exactly-once** database mutation semantics by committing the application query and the DBOS `transaction_completion` checkpoint row inside the **same database transaction**.

##### Example

```go
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
	"github.com/jackc/pgx/v5/pgxpool"
)

func transferFundsWorkflow(ctx dbos.Context, ds *dbos.DataSource, amount int64) (int64, error) {
	// Executes user SQL and records the step checkpoint in the same ACID transaction
	rowsAffected, err := dbos.RunAsTransaction(
		ctx,
		ds,
		func(txCtx context.Context, tx dbos.Tx) (int64, error) {
			res, err := tx.Exec(
				txCtx,
				"UPDATE ledger_accounts SET balance = balance - $1 WHERE account_id = 'acct_1'",
				amount,
			)
			if err != nil {
				return 0, err
			}
			return res.RowsAffected(), nil
		},
		dbos.WithStepName("debitAccountTransaction"),
		dbos.WithStepMaxRetries(3),
	)
	return rowsAffected, err
}

func ExampleRunAsTransaction() {
	ctx := context.Background()
	dbURL := os.Getenv("DBOS_SYSTEM_DATABASE_URL")

	appPool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		panic(err)
	}
	defer appPool.Close()

	dbosCtx, err := dbos.NewContext(ctx, dbos.Config{
		AppName:     "ledger-service",
		DatabaseURL: dbURL,
	})
	if err != nil {
		panic(err)
	}

	// Register transactional application DataSource (creates transaction_completion table)
	ds, err := dbos.NewDataSource(
		dbosCtx,
		appPool,
		dbos.WithDataSourceName("ledger_db"),
	)
	if err != nil {
		panic(err)
	}

	wf := func(wCtx dbos.Context, amt int64) (int64, error) {
		return transferFundsWorkflow(wCtx, ds, amt)
	}
	dbos.RegisterWorkflow(dbosCtx, wf, dbos.WithWorkflowName("transferFundsWorkflow"))

	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	handle, _ := dbos.RunWorkflow(dbosCtx, wf, int64(100))
	rows, _ := handle.GetResult()
	fmt.Printf("Rows updated: %d\n", rows)
}
```

---

### 3. PostgreSQL-Backed Workflow Queues, Concurrency Throttling, and Multi-Tenant Partitioning

DBOS implements persistent, distributed task queues directly in PostgreSQL using `SELECT ... FOR UPDATE SKIP LOCKED`, eliminating external message brokers while supporting multi-dimensional flow control.

- **Database-Backed Registration (`dbos.RegisterQueue`)**: Queues are stored in `dbos.workflow_queue`. Workers dynamically reload queue limits from the database, allowing runtime adjustments (`queue.SetGlobalConcurrency`, `queue.SetRateLimit`) without restarting worker nodes.
- **Two-Tier Concurrency Control**:
  - **Worker Concurrency (`WithWorkerConcurrency`)**: Enforced via an in-memory semaphore per Go process to prevent local CPU/RAM exhaustion.
  - **Global Concurrency (`WithGlobalConcurrency`)**: Enforced across all worker nodes via SQL count checks on `PENDING` workflows in `dbos.workflow_status`.
- **Priority Ordering**: Enabled natively on all queues. Dequeue queries order by `priority ASC NULLS FIRST, created_at ASC`:
  - Tasks **without** a priority run first (`NULLS FIRST`).
  - Lower integer values have **higher** precedence (`WithPriority(1)` executes before `WithPriority(10)`).
- **Deduplication**: Passing `WithDeduplicationID(key)` prevents duplicate tasks with the same key from being `ENQUEUED` or `PENDING` simultaneously. Callers can choose `DeduplicationPolicyReject` (returns `dbos.ErrQueueDeduplicated`) or `DeduplicationPolicyReturnExisting`.
- **Multi-Tenant Partitioned Queues**: Enqueueing with `WithQueuePartitionKey(tenantID)` isolates concurrency and rate limits **per partition key** (`WithPartitionConcurrency`, `WithPartitionWorkerConcurrency`, `WithPartitionRateLimiter`), preventing a single noisy tenant from starving others.
- **Dedicated Worker Pools**: Calling `dbosCtx.ListenQueues(dbosCtx, gpuQueue)` before `dbos.Launch` restricts a worker node to polling only the specified queues.

#### Queue Registration & Enqueue Options

| Category         | Option Function                                         | Behavior                                                                                         |
| :--------------- | :------------------------------------------------------ | :----------------------------------------------------------------------------------------------- |
| **Queue Option** | `WithWorkerConcurrency(n int)`                          | Max concurrent workflows from this queue on a single worker process                              |
| **Queue Option** | `WithGlobalConcurrency(n int)`                          | Max concurrent workflows from this queue across all worker processes                             |
| **Queue Option** | `WithRateLimiter(&RateLimiter{Limit, Period})`          | Caps total workflow starts across the cluster to `Limit` per `Period`                            |
| **Queue Option** | `WithPartitionConcurrency(n int)`                       | Max concurrent workflows per `partitionKey` globally across all workers                          |
| **Queue Option** | `WithPartitionWorkerConcurrency(n int)`                 | Max concurrent workflows per `partitionKey` on a single worker process                           |
| **Queue Option** | `WithPartitionRateLimiter(&RateLimiter{Limit, Period})` | Independent rate limit bucket applied to each `partitionKey`                                     |
| **Queue Option** | `WithQueueBasePollingInterval(d time.Duration)`         | Base interval between `FOR UPDATE SKIP LOCKED` polling queries                                   |
| **Queue Option** | `WithQueueOnConflict(policy QueueConflictResolution)`   | `QueueConflictNeverUpdate`, `QueueConflictAlwaysUpdate`, or `QueueConflictUpdateIfLatestVersion` |
| **Workflow Opt** | `WithQueue(queue Queue)`                                | Enqueues workflow into `ENQUEUED` state on the target `Queue`                                    |
| **Workflow Opt** | `WithPriority(priority uint)`                           | Sets queue priority (`1` to `2,147,483,647`; `1` runs before `10`)                               |
| **Workflow Opt** | `WithDeduplicationID(id string)`                        | Enforces uniqueness across active (`ENQUEUED` / `PENDING`) tasks in the queue                    |
| **Workflow Opt** | `WithDeduplicationPolicy(policy DeduplicationPolicy)`   | `DeduplicationPolicyReject` (default) or `DeduplicationPolicyReturnExisting`                     |
| **Workflow Opt** | `WithQueuePartitionKey(key string)`                     | Assigns partition key for per-tenant concurrency and rate limiting                               |
| **Workflow Opt** | `WithDelay(delay time.Duration)`                        | Enqueues workflow in `DELAYED` status until `delay` elapses                                      |

#### Interaction

```mermaid
flowchart TD
    Producer["Producer: dbos.RunWorkflow(WithQueue, WithPriority, WithQueuePartitionKey)"] --> Insert["INSERT INTO dbos.workflow_status (status = 'ENQUEUED')"]
    Insert --> Poll["Worker Poller: SELECT ... FOR UPDATE SKIP LOCKED"]
    Poll --> CheckLimits{"Check Global / Worker / Partition Concurrency & RateLimiter"}
    CheckLimits -->|"Capacity Exceeded"| Backoff["Leave Row ENQUEUED & Wait Next Poll Tick"]
    CheckLimits -->|"Within Limits"| Claim["UPDATE status = 'PENDING' & Dispatch Goroutine"]
    Claim --> Complete["Execute Steps & UPDATE status = 'SUCCESS'"]
```

#### Example

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

type JobPayload struct {
	TenantID string `json:"tenant_id"`
	TaskID   string `json:"task_id"`
}

func indexDocumentWorkflow(ctx dbos.Context, job JobPayload) (string, error) {
	return dbos.RunAsStep(ctx, func(stepCtx context.Context) (string, error) {
		return fmt.Sprintf("indexed %s for %s", job.TaskID, job.TenantID), nil
	}, dbos.WithStepName("embedAndIndex"))
}

func main() {
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:     "indexing-worker",
		DatabaseURL: os.Getenv("DBOS_SYSTEM_DATABASE_URL"),
	})
	if err != nil {
		panic(err)
	}

	dbos.RegisterWorkflow(dbosCtx, indexDocumentWorkflow)

	// Register a multi-tenant partitioned queue with global and per-tenant limits
	ingestQueue, err := dbos.RegisterQueue(
		dbosCtx,
		"document_ingestion_queue",
		dbos.WithWorkerConcurrency(10),
		dbos.WithGlobalConcurrency(50),
		dbos.WithRateLimiter(&dbos.RateLimiter{
			Limit:  200,
			Period: 1 * time.Minute,
		}),
		dbos.WithPartitionConcurrency(3),       // Max 3 active tasks per tenant globally
		dbos.WithPartitionWorkerConcurrency(2), // Max 2 active tasks per tenant on this node
		dbos.WithPartitionRateLimiter(&dbos.RateLimiter{
			Limit:  30,
			Period: 1 * time.Minute, // Max 30 tasks/min per tenant
		}),
		dbos.WithQueueBasePollingInterval(250*time.Millisecond),
		dbos.WithQueueOnConflict(dbos.QueueConflictAlwaysUpdate),
	)
	if err != nil {
		panic(err)
	}

	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	// Enqueue a high-priority deduplicated job scoped to tenant "acme-corp"
	handle, err := dbos.RunWorkflow(
		dbosCtx,
		indexDocumentWorkflow,
		JobPayload{TenantID: "acme-corp", TaskID: "doc-9001"},
		dbos.WithQueue(ingestQueue),
		dbos.WithQueuePartitionKey("acme-corp"),
		dbos.WithPriority(1),
		dbos.WithDeduplicationID("acme-doc-9001"),
		dbos.WithDeduplicationPolicy(dbos.DeduplicationPolicyReject),
	)
	if err != nil {
		panic(err)
	}

	// Verify duplicate submission is rejected while the first job is active
	_, dupErr := dbos.RunWorkflow(
		dbosCtx,
		indexDocumentWorkflow,
		JobPayload{TenantID: "acme-corp", TaskID: "doc-9001"},
		dbos.WithQueue(ingestQueue),
		dbos.WithQueuePartitionKey("acme-corp"),
		dbos.WithDeduplicationID("acme-doc-9001"),
	)
	if errors.Is(dupErr, dbos.ErrQueueDeduplicated) {
		fmt.Println("Duplicate task rejected as expected")
	}

	res, err := handle.GetResult()
	if err != nil {
		panic(err)
	}
	fmt.Println("Result:", res)
}
```

---

### 4. Durable Inter-Workflow Messaging, Events, and Real-Time Streams

DBOS provides three database-backed communication primitives leveraged across workflows and external clients, woken instantaneously via PostgreSQL `LISTEN/NOTIFY`.

- **FIFO Topic Messaging (`dbos.Send` / `dbos.Recv`)**:
  - `Send` inserts a message row into `dbos.notifications` for `(destinationID, topic)` and fires `pg_notify`. Accepts `WithIdempotencyKey(key)` for exactly-once delivery and `WithSendTransaction(tx)` to send atomically within an existing SQL transaction.
  - `Recv` blocks inside a workflow until the oldest unconsumed message on `topic` arrives or `timeout` elapses (returning `dbos.ErrTimeout`, which wraps `context.DeadlineExceeded`). Consumed messages are checkpointed in `dbos.operation_outputs` so crash recovery never double-consumes a message.
- **Key-Value State Publishing (`dbos.SetEvent` / `dbos.GetEvent`)**:
  - `SetEvent` upserts a key-value record in `dbos.workflow_events` (and appends to `dbos.workflow_events_history`) from inside a running workflow.
  - `GetEvent` allows external HTTP handlers or other workflows to await or read the latest value published under `key` for `targetWorkflowID`.
- **Durable Append-Only Streams (`dbos.WriteStream` / `dbos.ReadStream` / `dbos.CloseStream`)**:
  - Workflows stream incremental progress or LLM token chunks via `WriteStream(ctx, key, chunk)` and finalize with `CloseStream(ctx, key)` (also closed automatically when the workflow finishes).
  - External callers consume streams incrementally using `ReadStream` with `WithReadStreamFromOffset(offset)` and `WithReadStreamSnapshot()`.

#### Communication Primitives Comparison

| Primitive                     | Direction                   | Delivery Semantics                       | Backing Table          | Primary Use Case                                        |
| :---------------------------- | :-------------------------- | :--------------------------------------- | :--------------------- | :------------------------------------------------------ |
| `Send[P]` / `Recv[R]`         | Client/Workflow -> Workflow | Queued FIFO per `(destinationID, topic)` | `dbos.notifications`   | Human-in-the-loop approvals, webhook callbacks          |
| `SetEvent[P]` / `GetEvent[R]` | Workflow -> Client/Workflow | Latest value per `(workflowID, key)`     | `dbos.workflow_events` | Publishing milestone progress or intermediate artifacts |
| `WriteStream` / `ReadStream`  | Workflow -> Client/Workflow | Ordered append-only sequence (`offset`)  | `dbos.streams`         | Real-time token streaming, live log tailing             |

#### Interaction

```mermaid
sequenceDiagram
    participant Client as External HTTP Handler (dbos.Client)
    participant PG as PostgreSQL (notifications / events / streams)
    participant WF as Running Workflow (dbos.Context)

    WF->>PG: SetEvent(ctx, "status", "AWAITING_APPROVAL")
    PG-->>Client: LISTEN/NOTIFY wakes GetEvent("status")
    WF->>PG: Recv[Approval](ctx, "approval_topic", 24*time.Hour)
    Client->>PG: Send(ctx, wfID, Approval{Approved: true}, "approval_topic")
    PG-->>WF: LISTEN/NOTIFY delivers message & checkpoints operation_outputs
    WF->>PG: WriteStream(ctx, "output_stream", "Chunk 1")
    WF->>PG: CloseStream(ctx, "output_stream")
    Client->>PG: ReadStream(ctx, wfID, "output_stream", WithReadStreamFromOffset(0))
```

#### Example

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

type ApprovalSignal struct {
	Approved bool   `json:"approved"`
	ByUser   string `json:"by_user"`
}

func deploymentWorkflow(ctx dbos.Context, env string) (string, error) {
	// 1. Publish current workflow state via SetEvent
	if err := dbos.SetEvent(ctx, "deploy_phase", "WAITING_FOR_APPROVAL"); err != nil {
		return "", err
	}

	// 2. Durably wait up to 1 hour for an approval signal on topic "deploy_gate"
	sig, err := dbos.Recv[ApprovalSignal](ctx, "deploy_gate", 1*time.Hour)
	if err != nil {
		if errors.Is(err, dbos.ErrTimeout) {
			return "ABORTED_TIMEOUT", nil
		}
		return "", err
	}
	if !sig.Approved {
		return fmt.Sprintf("REJECTED_BY_%s", sig.ByUser), nil
	}

	// 3. Stream live deployment logs to external listeners
	if err := dbos.SetEvent(ctx, "deploy_phase", "ROLLING_OUT"); err != nil {
		return "", err
	}
	for _, stepLog := range []string{"Pulling image...", "Migrating DB...", "Traffic shifted!"} {
		if err := dbos.WriteStream(ctx, "deploy_logs", stepLog); err != nil {
			return "", err
		}
	}
	if err := dbos.CloseStream(ctx, "deploy_logs"); err != nil {
		return "", err
	}

	return fmt.Sprintf("DEPLOYED_TO_%s_BY_%s", env, sig.ByUser), nil
}

func main() {
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:     "deploy-orchestrator",
		DatabaseURL: os.Getenv("DBOS_SYSTEM_DATABASE_URL"),
	})
	if err != nil {
		panic(err)
	}
	dbos.RegisterWorkflow(dbosCtx, deploymentWorkflow)
	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	wfID := "deploy-prod-2026-11-10"
	handle, err := dbos.RunWorkflow(dbosCtx, deploymentWorkflow, "production", dbos.WithWorkflowID(wfID))
	if err != nil {
		panic(err)
	}

	// Wait for workflow to enter WAITING_FOR_APPROVAL state
	phase, err := dbos.GetEvent[string](dbosCtx, wfID, "deploy_phase", 5*time.Second)
	if err != nil {
		panic(err)
	}
	fmt.Println("Workflow phase:", phase)

	// Send idempotent approval message to the waiting workflow
	err = dbos.Send(
		dbosCtx,
		wfID,
		ApprovalSignal{Approved: true, ByUser: "sre-lead"},
		"deploy_gate",
		dbos.WithIdempotencyKey("approve-deploy-prod-1"),
	)
	if err != nil {
		panic(err)
	}

	// Read all streamed log chunks once closed
	logs, closed, err := dbos.ReadStream[string](dbosCtx, wfID, "deploy_logs")
	if err != nil {
		panic(err)
	}
	fmt.Printf("Stream closed=%v, logs=%v\n", closed, logs)

	finalStatus, _ := handle.GetResult()
	fmt.Println("Final workflow outcome:", finalStatus)
}
```

---

### 5. Crash-Resilient Durable Timers, Cron Schedules, and Workflow Debouncing

DBOS persists timer deadlines, recurring cron schedules, and debounce windows in the system database so time-driven execution survives process restarts.

- **Durable Sleep (`dbos.Sleep`)**:
  - When `dbos.Sleep(ctx, duration)` executes for the first time, DBOS computes $\text{wakeUpTime} = \text{now} + \text{duration}$ and records it in `dbos.operation_outputs`.
  - If the process crashes and restarts during a multi-day sleep, replay reads the checkpointed `wakeUpTime` and sleeps only for the remaining duration $\max(0, \text{wakeUpTime} - \text{now})$.
- **Dynamic Cron Scheduling (`dbos.CreateSchedule` / `dbos.ApplySchedules`)**:
  - Schedules are stored in `dbos.workflow_schedules` using a **6-field cron syntax** (`second minute hour dayOfMonth month dayOfWeek`, e.g., `"0 */15 * * * *"` for every 15 minutes at second 0).
  - Scheduled workflows accept `(ctx dbos.Context, input dbos.ScheduledWorkflowInput)`, where `input.ScheduledTime` holds the tick timestamp and `dbos.DecodeScheduleContext[T](input)` extracts custom configuration.
- **Workflow Debouncing (`dbos.NewDebouncer`)**:
  - Coalesces rapid, repeated triggers for the same key (e.g., user edits or webhook bursts) so only a single workflow executes after a quiet period (`delay`) or when a maximum ceiling (`WithDebouncerTimeout`) is reached.

#### Time-Based Execution Primitives

| Primitive          | Signature / Entry Point                                     | Backing Table             | Behavior Across Restarts                                    |
| :----------------- | :---------------------------------------------------------- | :------------------------ | :---------------------------------------------------------- |
| **Durable Timer**  | `dbos.Sleep(ctx, duration)`                                 | `dbos.operation_outputs`  | Preserves original absolute wake-up timestamp               |
| **Cron Scheduler** | `dbos.CreateSchedule(ctx, dbos.ScheduleSpec{...})`          | `dbos.workflow_schedules` | Persisted in DB; dynamically editable without redeploying   |
| **Debouncer**      | `dbos.NewDebouncer(ctx, wf, WithDebouncerTimeout(maxWait))` | `dbos.debouncer`          | Coalesces rapid triggers per key; uses latest input payload |

#### Interaction

```mermaid
sequenceDiagram
    participant App as Application / Scheduler
    participant SysDB as PostgreSQL (operation_outputs / schedules)
    participant WF as Scheduled Workflow

    App->>SysDB: CreateSchedule("nightly-cleanup", "0 0 0 * * *")
    SysDB-->>WF: Cron tick triggers workflow(ctx, ScheduledWorkflowInput)
    WF->>SysDB: dbos.Sleep(ctx, 2*time.Hour) -> Persist wakeUpTime = T0 + 2h
    Note over WF,SysDB: Worker restarts at T0 + 1.5h
    SysDB-->>WF: Replay reads wakeUpTime = T0 + 2h (Sleeps remaining 30m only)
    WF->>SysDB: Complete workflow & record status = 'SUCCESS'
```

#### Example

```go
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

type CleanupConfig struct {
	RetentionDays int `json:"retention_days"`
}

func archiveOldRecordsWorkflow(ctx dbos.Context, input dbos.ScheduledWorkflowInput) (string, error) {
	cfg, err := dbos.DecodeScheduleContext[CleanupConfig](input)
	if err != nil {
		return "", err
	}

	// Durable sleep: deadline is checkpointed in dbos.operation_outputs
	if _, err := dbos.Sleep(ctx, 500*time.Millisecond); err != nil {
		return "", err
	}

	return fmt.Sprintf(
		"archived records older than %d days for tick %s",
		cfg.RetentionDays,
		input.ScheduledTime.Format(time.RFC3339),
	), nil
}

func main() {
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:     "cron-archiver",
		DatabaseURL: os.Getenv("DBOS_SYSTEM_DATABASE_URL"),
	})
	if err != nil {
		panic(err)
	}

	dbos.RegisterWorkflow(dbosCtx, archiveOldRecordsWorkflow)

	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	// Register a dynamic database-backed cron schedule (6-field cron: sec min hour dom mon dow)
	err = dbos.ApplySchedules(dbosCtx, []dbos.ScheduleSpec{
		{
			ScheduleName: "every-30-minutes-archive",
			Schedule:     "0 */30 * * * *",
			Workflow:     archiveOldRecordsWorkflow,
			Context:      CleanupConfig{RetentionDays: 90},
		},
	})
	if err != nil {
		panic(err)
	}
	fmt.Println("Cron schedule applied successfully")
}
```

---

### 6. Workflow Introspection, Lifecycle Control, Versioning, and Live Code Patching

DBOS provides programmatic APIs and the `dbos` CLI (`github.com/dbos-inc/dbos-transact-golang/cmd/dbos`) to inspect, cancel, resume, fork, and safely upgrade workflows across deployments.

- **Lifecycle Control APIs**:
  - **`CancelWorkflow(ctx, wfID, WithCancelChildren())`**: Marks the workflow `CANCELLED` and preempts execution before the next step begins.
  - **`ResumeWorkflow[R](ctx, wfID, WithResumeQueue(q))`**: Resumes a `CANCELLED` or `MAX_RECOVERY_ATTEMPTS_EXCEEDED` workflow directly from its last completed step checkpoint.
  - **`ForkWorkflow[R](ctx, ForkWorkflowInput{OriginalWorkflowID, StartStep})`**: Clones step checkpoints `0` through `StartStep - 1` into a brand-new workflow ID and executes live from `StartStep` onward—ideal for debugging production failures or re-running after a downstream fix.
- **Querying & Step Inspection**:
  - **`ListWorkflows(ctx, WithFilterStatus(...), WithFilterName(...), WithFilterLimit(...))`**: Queries `dbos.workflow_status` with composable `WithFilter*` predicates.
  - **`GetWorkflowSteps(ctx, wfID, WithStepsLoadOutput(true))`**: Returns ordered `[]StepInfo` (`StepID`, `StepName`, `Output`, `Error`, `ChildWorkflowIDs`).
- **Upgrading Workflows Across Deployments**:
  - **Blue-Green Versioning (`ApplicationVersion`)**: By default, `dbos.Launch` only recovers `PENDING` workflows matching the process's `ApplicationVersion`, allowing old workers to drain in-flight workflows while new workers run updated code.
  - **In-Place Code Patching (`dbos.Patch` / `dbos.DeprecatePatch`)**: When modifying workflow control flow in-place without blue-green draining, `dbos.Patch(ctx, "patch-name")` records a marker in `operation_outputs`, returning `true` for new executions and `false` for replays that already passed that point prior to the patch. Once all pre-patch workflows complete, replace `dbos.Patch` with `dbos.DeprecatePatch(ctx, "patch-name")` before removing the patch entirely.

#### Programmatic Management & CLI Equivalence

| Operation             | Go SDK Function                                        | CLI Command (`cmd/dbos`)                         |
| :-------------------- | :----------------------------------------------------- | :----------------------------------------------- |
| **List Workflows**    | `dbos.ListWorkflows(ctx, dbos.WithFilterStatus(...))`  | `dbos workflow list --status PENDING --limit 20` |
| **Get Workflow Info** | `dbos.RetrieveWorkflow[R](ctx, wfID)` + `.GetStatus()` | `dbos workflow get <workflow-id>`                |
| **Inspect Steps**     | `dbos.GetWorkflowSteps(ctx, wfID)`                     | `dbos workflow steps <workflow-id>`              |
| **Cancel Workflow**   | `dbos.CancelWorkflow(ctx, wfID, WithCancelChildren())` | `dbos workflow cancel <workflow-id>`             |
| **Resume Workflow**   | `dbos.ResumeWorkflow[R](ctx, wfID)`                    | `dbos workflow resume <workflow-id>`             |
| **Fork Workflow**     | `dbos.ForkWorkflow[R](ctx, ForkWorkflowInput{...})`    | `dbos workflow fork <workflow-id> --step 2`      |
| **Run Migrations**    | `dbos.Migrate(ctx, cfg)`                               | `dbos migrate`                                   |

#### Interaction

```mermaid
flowchart TD
    Orig["Original Workflow (wf-orig): Steps 0, 1 Succeeded; Step 2 Failed"] --> Inspect["dbos.GetWorkflowSteps(ctx, 'wf-orig')"]
    Inspect --> Choice{"Remediation Strategy"}
    Choice -->|"Retry From Failed Step 2"| Resume["dbos.ResumeWorkflow(ctx, 'wf-orig')"]
    Choice -->|"Branch Into New ID From Step 1"| Fork["dbos.ForkWorkflow(ctx, ForkWorkflowInput{OriginalWorkflowID: 'wf-orig', StartStep: 1})"]
    Resume --> ReExec2["Skip Steps 0 & 1; Re-execute Step 2 on 'wf-orig'"]
    Fork --> Copy0["Copy Step 0 Checkpoint to 'wf-forked' & Execute Step 1+ Live"]
```

#### Example

```go
package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/dbos-inc/dbos-transact-golang/dbos"
)

func paymentPipeline(ctx dbos.Context, orderID string) (string, error) {
	// Safely evolve workflow control flow in-place using dbos.Patch
	useV2FraudCheck, err := dbos.Patch(ctx, "fraud-check-v2")
	if err != nil {
		return "", err
	}

	if useV2FraudCheck {
		_, err = dbos.RunAsStep(ctx, func(c context.Context) (string, error) {
			return "fraud_v2_passed", nil
		}, dbos.WithStepName("fraudCheckV2"))
	} else {
		_, err = dbos.RunAsStep(ctx, func(c context.Context) (string, error) {
			return "fraud_v1_passed", nil
		}, dbos.WithStepName("fraudCheckV1"))
	}
	if err != nil {
		return "", err
	}

	// Step 1: Settlement
	settled, err := dbos.RunAsStep(ctx, func(c context.Context) (string, error) {
		return fmt.Sprintf("settled_%s", orderID), nil
	}, dbos.WithStepName("settleOrder"))
	return settled, err
}

func main() {
	dbosCtx, err := dbos.NewContext(context.Background(), dbos.Config{
		AppName:            "payment-admin-demo",
		ApplicationVersion: "2.1.0",
		DatabaseURL:        os.Getenv("DBOS_SYSTEM_DATABASE_URL"),
	})
	if err != nil {
		panic(err)
	}
	dbos.RegisterWorkflow(dbosCtx, paymentPipeline, dbos.WithWorkflowName("paymentPipeline"))
	if err := dbos.Launch(dbosCtx); err != nil {
		panic(err)
	}
	defer dbos.Shutdown(dbosCtx, 5*time.Second)

	// 1. Run original workflow
	origHandle, err := dbos.RunWorkflow(dbosCtx, paymentPipeline, "ORD-777", dbos.WithWorkflowID("wf-ord-777"))
	if err != nil {
		panic(err)
	}
	_, _ = origHandle.GetResult()

	// 2. Inspect recorded steps
	steps, err := dbos.GetWorkflowSteps(dbosCtx, "wf-ord-777", dbos.WithStepsLoadOutput(true))
	if err != nil {
		panic(err)
	}
	for _, s := range steps {
		fmt.Printf("Step #%d (%s) -> output=%v\n", s.StepID, s.StepName, s.Output)
	}

	// 3. Fork workflow from Step 1 (reuses Step 0 checkpoint, re-executes Step 1 under a new ID)
	forkHandle, err := dbos.ForkWorkflow[string](dbosCtx, dbos.ForkWorkflowInput{
		OriginalWorkflowID: "wf-ord-777",
		ForkedWorkflowID:   "wf-ord-777-fork-1",
		StartStep:          1,
	})
	if err != nil {
		panic(err)
	}
	forkResult, _ := forkHandle.GetResult()
	fmt.Println("Forked workflow result:", forkResult)

	// 4. Query recent successful workflows using WithFilter* options
	recent, err := dbos.ListWorkflows(
		dbosCtx,
		dbos.WithFilterName("paymentPipeline"),
		dbos.WithFilterStatus(dbos.WorkflowStatusSuccess),
		dbos.WithFilterCreatedAfter(time.Now().Add(-1*time.Hour)),
		dbos.WithFilterSortDesc(),
		dbos.WithFilterLimit(10),
	)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Listed %d completed paymentPipeline workflows\n", len(recent))
}
```

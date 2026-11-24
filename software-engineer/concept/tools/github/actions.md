# GitHub Actions CI/CD Configuration: Beginner's Guide & Core Concepts

| Metadata      | Value                      |
| ------------- | -------------------------- |
| Author        | Lyzander Marciano Andrylie |
| Creation Date | Nov 24, 2026               |
| Last Updated  | Nov 24, 2026               |

## References

- [Workflows in GitHub Actions](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows): Core architecture of workflows, events, jobs, steps, actions, and runners
- [Workflow Syntax for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax): Complete YAML schema reference for `.github/workflows/*.yml`
- [Contexts Reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts): Built-in metadata objects (`github`, `env`, `vars`, `secrets`, `needs`, `matrix`, `runner`)
- [Evaluate Expressions in Workflows and Actions](https://docs.github.com/actions/reference/evaluate-expressions-in-workflows-and-actions): Conditional logic, operators, `hashFiles()`, and status check functions
- [Secrets in GitHub Actions](https://docs.github.com/en/actions/concepts/security/secrets): Encrypted secrets, scoping across org/repo/environment, and fork security behavior
- [Dependency Caching](https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching): Speeding up installs with `actions/cache`, cache keys, scopes, and eviction limits
- [Workflow Artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts): Sharing build outputs between jobs and storing downloadable deliverables
- [Deployment Environments](https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments): Environment-scoped secrets, branch rules, and required manual reviewers
- [Reusing Workflow Configurations](https://docs.github.com/en/actions/concepts/workflows-and-actions/reusing-workflow-configurations): Comparing reusable workflows (`workflow_call`) and composite actions
- [ci_cd.md](../gitlab/ci_cd.md): Companion beginner's guide to GitLab CI/CD `.gitlab-ci.yml` configuration
- [config.md](../git/config.md): Git configuration scopes, identity settings, and everyday Git workflow defaults
- [oidc.md](../../auth/oidc.md): Workload OIDC federation for authenticating GitHub Actions jobs to cloud providers without static secrets

## Description

**GitHub Actions** is GitHub's native CI/CD and repository automation platform configured via YAML files stored in `.github/workflows/`. Whenever a repository event occurs (such as a `push`, `pull_request`, scheduled cron, or manual trigger), GitHub provisions clean virtual machine runners to execute your build, test, and deployment workflows automatically.

## Concepts

### 1. How GitHub Actions Works: Events, Workflows, Jobs, Steps & Runners

Unlike platforms that rely on a single root config file, GitHub Actions lets you organize automation into **multiple focused YAML files** under `.github/workflows/` (for example, `ci.yml`, `deploy.yml`, and `release.yml`).

- **Core Hierarchy (`Event → Workflow → Jobs → Steps`)**:
  - **Event (`on:`)**: The trigger that starts a workflow (Git push, pull request, release published, cron schedule, or manual button click).
  - **Workflow**: One YAML file in `.github/workflows/` (`.yml` or `.yaml`) containing one or more jobs.
  - **Jobs**: Independent units of work that **run in parallel by default**, each on its own fresh runner VM. There is no `stages:` keyword—use `needs:` when one job must wait for another.
  - **Steps**: Ordered tasks inside a job that run **sequentially on the same VM** and share the same working directory. Each step either invokes a reusable **Action** (`uses:`) or runs shell commands (`run:`).
- **Runners (The Machines)**:
  - **GitHub-hosted runners** (`ubuntu-latest`, `macos-latest`, `windows-latest`) are freshly provisioned VMs destroyed after every job, ensuring clean builds with zero leftover state.
  - **Self-hosted runners** let you run jobs on your own servers or Kubernetes cluster (via Actions Runner Controller) for private network access or custom hardware.

#### Interaction

```mermaid
flowchart LR
    Event["Repository Event<br>(push / pull_request)"] -->|"Triggers"| WF["Workflow File<br>(.github/workflows/ci.yml)"]
    WF -->|"Runs in parallel"| J1["Job: lint<br>(Runner VM #1)<br>Step 1 -> Step 2"]
    WF -->|"Runs in parallel"| J2["Job: test<br>(Runner VM #2)<br>Step 1 -> Step 2"]
    J1 -->|"needs: [lint, test]"| J3["Job: deploy<br>(Runner VM #3)"]
    J2 -->|"needs: [lint, test]"| J3
```

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Check formatting
        run: echo "Running linter..."

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Run unit tests
        run: echo "Running tests..."

  deploy:
    needs: [lint, test] # Runs only after both lint and test succeed
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Deploy app
        run: echo "Deploying application..."
```

> [!IMPORTANT]
> GitHub Actions does **not** automatically clone your repository onto the runner. Almost every job must include `- uses: actions/checkout@v7` as its first step before reading files or running project scripts.

---

### 2. Anatomy of a Workflow & Job: Triggers (`on`), Runners, Steps & `services`

A workflow combines **when** to run (`on:`), **where** to run (`runs-on:`), and **what** to run (`steps:`).

- **Common Triggers (`on:`)**:
  - `push` / `pull_request`: Filter by `branches:`, `tags:`, or `paths:` / `paths-ignore:` (for example, skip CI when only `*.md` docs change).
  - `workflow_dispatch`: Adds a manual **Run workflow** button in the GitHub UI (and supports typed user `inputs:`).
  - `schedule`: Runs on a POSIX cron schedule in **UTC** (e.g., `cron: '0 2 * * *'`).
- **Shell State Between Steps**:
  - Each `run:` step executes in its **own subshell** (`bash -e {0}` on Linux/macOS by default, so any non-zero exit code fails the step immediately).
  - Running `export FOO=bar` in step 1 does **not** persist into step 2. To pass values to later steps in the same job, append `KEY=VALUE` to `"$GITHUB_ENV"` (for env vars) or `"$GITHUB_OUTPUT"` (for step outputs).
- **Sidecar Containers (`services:`)**:
  - Spin up databases or caches (`postgres:16-alpine`, `redis:7-alpine`) alongside your job for integration tests.
  - When the job runs directly on a Linux runner VM (mapping `ports: ['5432:5432']`), connect via `localhost:5432`. If the job runs inside `container:`, connect via the service name (`postgres:5432`).

| Keyword             | Scope    | Purpose                                                               |
| :------------------ | :------- | :-------------------------------------------------------------------- |
| `on`                | Workflow | Events and branch/path filters that trigger the workflow              |
| `permissions`       | Both     | Least-privilege scopes granted to the automatic `GITHUB_TOKEN`        |
| `concurrency`       | Both     | Groups runs and optionally cancels superseded in-progress runs        |
| `runs-on`           | Job      | Runner VM image (`ubuntu-latest`) or self-hosted runner labels        |
| `needs`             | Job      | Upstream job IDs that must finish before this job starts              |
| `if`                | Job/Step | Conditional expression controlling whether the job or step executes   |
| `services`          | Job      | Sidecar Docker containers (DB, Redis) attached to the job             |
| `timeout-minutes`   | Job/Step | Max runtime before cancellation (defaults to 360 minutes per job)     |
| `continue-on-error` | Job/Step | Allows a step or job to fail without failing the workflow             |
| `uses` / `with`     | Step     | Runs a reusable Action (`owner/repo@vX`) with input parameters        |
| `run`               | Step     | Executes inline single-line or multi-line (`\|`) shell commands       |

```yaml
name: Integration Tests

on:
  pull_request:
    paths-ignore:
      - "**/*.md"
  workflow_dispatch: # Enables manual runs from the Actions tab

jobs:
  integration:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: ci_user
          POSTGRES_PASSWORD: ci_password
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
          cache: "pip"
      - name: Set shared environment variable
        run: echo "DATABASE_URL=postgresql://ci_user:ci_password@localhost:5432/test_db" >> "$GITHUB_ENV"
      - name: Install dependencies and test
        run: |
          pip install -r requirements.txt
          pytest tests/integration
```

---

### 3. Contexts, Variables, Secrets & `permissions` (`GITHUB_TOKEN`)

GitHub Actions injects runtime metadata and configuration through **contexts** evaluated with `${{ ... }}` expression syntax.

- **Three Places Configuration Lives**:
  1. **YAML `env:`** (workflow, job, or step level): Non-sensitive values checked into Git. Narrower scopes override broader ones (`step` > `job` > `workflow`).
  2. **Configuration Variables (`vars.*`)**: Plain-text values managed in GitHub Settings (`Settings → Secrets and variables → Actions → Variables`) at Organization, Repository, or Environment scope.
  3. **Encrypted Secrets (`secrets.*`)**: Sensitive credentials managed in GitHub Settings, automatically masked in logs, and **never exposed to pull requests from external forks** triggered by `pull_request`.
- **`GITHUB_TOKEN` & Least-Privilege `permissions:`**:
  - GitHub automatically creates a short-lived `secrets.GITHUB_TOKEN` for every workflow run so jobs can read the repo, comment on PRs, or push packages to GitHub Container Registry (`ghcr.io`).
  - Always declare an explicit `permissions:` block (e.g., `contents: read` at the workflow level, adding `packages: write` only on the publish job) so compromised third-party actions cannot mutate your repo.
  - For AWS, GCP, or Azure deployments, grant `id-token: write` to mint short-lived OIDC JWTs instead of storing static cloud access keys (see [oidc.md](../../auth/oidc.md)).

| Expression / Context        | Example Value                       | Common Use Case                                                |
| :-------------------------- | :---------------------------------- | :------------------------------------------------------------- |
| `github.ref_name`           | `main`, `v1.4.0`                    | Short branch or tag name that triggered the run                |
| `github.sha`                | `a1b2c3d4e5...`                     | Full 40-character commit SHA for immutable image/release tags  |
| `github.event_name`         | `push`, `pull_request`              | Branching logic in `if:` conditionals                          |
| `github.repository`         | `octo-org/shop-api`                 | Owner and repository slug (useful for `ghcr.io` image paths)   |
| `runner.os`                 | `Linux`, `macOS`, `Windows`         | OS-specific cache keys and conditional steps                   |
| `vars.API_BASE_URL`         | `https://staging.example.com`       | Non-sensitive repo/environment setting from GitHub UI          |
| `secrets.GITHUB_TOKEN`      | *(masked short-lived token)*        | Authenticating with GitHub APIs and `ghcr.io`                  |

```yaml
name: Build & Push Container

on:
  push:
    branches: [main]

permissions:
  contents: read # Least-privilege default for the whole workflow

env:
  REGISTRY: ghcr.io

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write # Needed only by this job to push to GHCR
    steps:
      - uses: actions/checkout@v7
      - name: Log in to GitHub Container Registry
        env:
          CR_PAT: ${{ secrets.GITHUB_TOKEN }}
        run: echo "$CR_PAT" | docker login "$REGISTRY" -u "${{ github.actor }}" --password-stdin
      - name: Build and push image
        run: |
          IMAGE="$REGISTRY/${{ github.repository }}:${{ github.sha }}"
          docker build -t "$IMAGE" .
          docker push "$IMAGE"
```

> [!WARNING]
> **Prevent Script Injection**: Never place untrusted values (such as `${{ github.event.pull_request.title }}` or `${{ github.event.issue.body }}`) directly inside a `run:` shell script—GitHub expands `${{ ... }}` *before* the shell parses the command, allowing arbitrary shell execution. Assign the expression to a step `env:` variable and reference it as a quoted shell variable (`"$PR_TITLE"`).

---

### 4. Passing Files & Speeding Up Runs: Artifacts vs Caching

Because every job runs on a separate fresh VM, files created in `build` do not exist in `test`, and packages installed in run #1 are gone in run #2. GitHub Actions solves these two problems with **Artifacts** and **Caching**.

| Dimension             | Artifacts (`upload-artifact` / `download-artifact`)          | Dependency Cache (`actions/cache` / `setup-*` `cache:`)        |
| :-------------------- | :----------------------------------------------------------- | :------------------------------------------------------------- |
| **Primary Purpose**   | Pass **build outputs** between jobs in the *same* run        | Reuse **downloaded packages** across *different* workflow runs |
| **Typical Files**     | Compiled bundles (`dist/`), binaries, test/coverage reports  | `~/.npm`, `~/.cache/pip`, Go module cache, `~/.m2`             |
| **Reliability**       | **Guaranteed** within the run once uploaded                  | **Best-effort** optimization (builds must survive a cache miss)|
| **How Retrieved**     | Explicit `actions/download-artifact@v8` step in consumer job | Automatic restore at start of job (and save at job end)        |
| **Retention & Limits**| Default **90 days** (set `retention-days:` lower to save GB) | Evicted after **7 days** unused; 10 GB default per repository  |
| **Branch Isolation**  | Scoped to one workflow run (downloadable in UI & API)        | Readable from current branch, PR base branch, and default branch|

- **Essential Best Practices**:
  - **Prefer Built-In `setup-*` Caching**: Official setup actions (`actions/setup-node@v7` with `cache: 'npm'`, `actions/setup-python@v7` with `cache: 'pip'`, `actions/setup-go` with `cache: true`) configure paths and lockfile keys automatically.
  - **Use `hashFiles()` with `actions/cache@v6`**: When caching custom directories, include `runner.os` and `hashFiles('**/package-lock.json')` in `key:`, plus a shorter prefix in `restore-keys:` for partial fallback matches.
  - **Set `retention-days:` on Artifacts**: Lowering retention from the 90-day default to `7` or `14` days prevents intermediate CI builds from eating your storage quota.

#### Interaction

```mermaid
flowchart LR
    subgraph CacheStore ["GitHub Cache (7-day idle TTL)"]
        C["npm cache<br>(Keyed by OS + package-lock.json hash)"]
    end

    subgraph Run ["Single Workflow Run"]
        Build["Job: build<br>(VM #1: npm ci -> npm run build)"]
        Test["Job: test<br>(VM #2: downloads dist/)"]
        Deploy["Job: deploy<br>(VM #3: downloads dist/)"]
    end

    subgraph ArtifactStore ["Workflow Artifacts (retention-days: 7)"]
        A["dist-bundle archive"]
    end

    C <-->|"Auto restore & save"| Build
    C -->|"Restore"| Test
    Build -->|"actions/upload-artifact@v7"| A
    A -->|"actions/download-artifact@v8"| Test
    A -->|"actions/download-artifact@v8"| Deploy
```

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: "22"
          cache: "npm" # Built-in caching keyed automatically on package-lock.json
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v7
        with:
          name: web-dist
          path: dist/
          retention-days: 7

  test-bundle:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/download-artifact@v8
        with:
          name: web-dist
          path: dist/
      - run: ls -la dist/
```

---

### 5. Controlling Execution: `needs`, `if`, `concurrency`, `matrix` & Environments

Five workflow features give you full control over execution speed, test coverage, and deployment safety.

#### a. Job Dependencies (`needs`) & Conditionals (`if`)

- **`needs:`** creates a Directed Acyclic Graph (DAG): a job waits until all listed jobs succeed before starting.
- **`if:`** skips a job or step when a condition is false. Inside `if:`, GitHub wraps the expression automatically, so `${{ ... }}` is optional. Use status functions (`success()`, `failure()`, `always()`, `cancelled()`) when a cleanup or notification step must run even after a failure.

#### b. Canceling Superseded Runs (`concurrency`)

- Pushing multiple quick commits to an open PR spawns redundant overlapping runs.
- Adding a top-level `concurrency:` block keyed by workflow and ref cancels older in-progress PR runs automatically—saving runner minutes.
- **Deployment Gotcha**: Set `cancel-in-progress: false` for deployment workflows so a new merge to `main` queues behind an active production rollout instead of killing it mid-deploy.

#### c. Testing Across Versions (`strategy.matrix`)

- A `matrix` expands one job definition into parallel jobs for every combination of variables (for example, 2 OSes × 2 Node versions = 4 parallel jobs).
- Set `fail-fast: false` if you want all matrix jobs to finish reporting results even when one combination fails.

#### d. Deployment Gates (`environment`)

- Attaching `environment: production` to a deploy job links it to GitHub's **Environments** feature (`Settings → Environments`), which enforces:
  - **Required Reviewers**: Pauses the job until designated team members click **Approve and deploy**.
  - **Deployment Branch Rules**: Restricts `production` deployments to `main` or release tags only.
  - **Environment Secrets**: Withholds production secrets until approval passes and the job is dispatched to a runner.

#### Interaction

```mermaid
flowchart LR
    Start["Event: push / PR"] --> Lint["Job: lint"]
    Start --> M1["Job: test (Node 20)"]
    Start --> M2["Job: test (Node 22)"]

    Lint -->|"needs: [lint, test]"| Stage["Job: deploy-staging<br>(Only on push to main)"]
    M1 --> Stage
    M2 --> Stage
    Stage -->|"needs: deploy-staging"| Gate{"Environment: production<br>(Required reviewer approval)"}
    Gate -->|"Approved"| Prod["Job: deploy-prod"]
```

```yaml
name: Matrix CI & Gated Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        node-version: ["20", "22"]
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"
      - run: npm ci
      - run: npm test

  deploy-prod:
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/checkout@v7
      - name: Deploy to production
        env:
          DEPLOY_TOKEN: ${{ secrets.PROD_DEPLOY_TOKEN }} # Environment-scoped secret
        run: ./scripts/deploy.sh production
```

---

### 6. Keeping Config DRY: Composite Actions & Reusable Workflows

GitHub Actions does not merge external YAML files via `include:` or `extends:`. Instead, you share logic across workflows and repositories with **Composite Actions** and **Reusable Workflows**.

| Feature               | Composite Action (`.github/actions/<name>/action.yml`)        | Reusable Workflow (`.github/workflows/<name>.yml`)               |
| :-------------------- | :------------------------------------------------------------ | :--------------------------------------------------------------- |
| **Granularity**       | Bundles multiple **steps** into one custom step               | Bundles one or more complete **jobs** (with their own runners)   |
| **Where Called**      | Inside a job's `steps:` (`uses: ./.github/actions/setup`)     | Directly as a job (`jobs.<id>.uses: ./.github/workflows/ci.yml`) |
| **Can Access Secrets**| No (must pass values explicitly via `inputs:`)                | Yes (explicit `secrets:` or `secrets: inherit` within same org)  |
| **Log Visibility**    | Grouped under a single step in logs                           | Each job and step is logged separately in real time              |
| **Best Used For**     | Repeated setup sequences (checkout + setup runtime + install) | Standardizing entire CI/CD pipelines across many repositories    |

- **Pinning Third-Party Actions Safely**:
  - Official actions like `actions/checkout@v7` are convenient for getting started, while security-sensitive repositories pin third-party actions to an **immutable full commit SHA** (`uses: owner/action@<40-char-sha> # v2.1.0`) to prevent supply-chain tag tampering. Never reference `@main` on external repositories.

```yaml
# .github/workflows/reusable-node-test.yml (Called workflow)
name: Reusable Node Test

on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: "22"

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: ${{ inputs.node-version }}
          cache: "npm"
      - run: npm ci
      - run: npm test
```

```yaml
# .github/workflows/ci.yml (Caller workflow)
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  run-tests:
    uses: ./.github/workflows/reusable-node-test.yml
    with:
      node-version: "22"
```

---

### 7. Complete Beginner Starter Workflow & Debugging Checklist

This end-to-end `.github/workflows/ci-cd.yml` combines every core concept for a Node.js web service: pull request validation, stale-run cancellation, least-privilege permissions, cached builds, artifact handoff, automatic staging deploys, and reviewer-gated production deploys.

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: "22"
          cache: "npm"
      - run: npm ci
      - run: npm run lint

  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: "22"
          cache: "npm"
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v7
        with:
          name: app-dist
          path: dist/
          retention-days: 7

  test:
    needs: build
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: "22"
          cache: "npm"
      - uses: actions/download-artifact@v8
        with:
          name: app-dist
          path: dist/
      - run: npm ci
      - run: npm test -- --ci

  deploy-staging:
    needs: [lint, build, test]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: app-dist
          path: dist/
      - name: Deploy to staging
        run: echo "Deploying dist/ (${{ github.sha }}) to staging..."

  deploy-production:
    needs: [build, deploy-staging]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production # Configure Required Reviewers in Settings -> Environments
      url: https://app.example.com
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: app-dist
          path: dist/
      - name: Deploy to production
        run: echo "Deploying dist/ (${{ github.sha }}) to production..."
```

#### Validation & Common Beginner Pitfalls

- **Debug Logging**: Click **Re-run jobs → Enable debug logging** on any failed run in the **Actions** tab (or set repository secrets `ACTIONS_STEP_DEBUG=true` and `ACTIONS_RUNNER_DEBUG=true` for persistent verbose output).
- **Local Linting**: Run `actionlint` locally (or in a pre-commit hook) to catch invalid expressions, typos in context names, and shellcheck issues before pushing.

| Symptom                                     | Most Likely Cause                                                      | Fix                                                                        |
| :------------------------------------------ | :--------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| **Commands fail with `No such file`**       | Forgot `actions/checkout@v7` step on the job                           | Add `- uses: actions/checkout@v7` as the first step                        |
| **`export VAR=1` is empty in next step**    | Every `run:` step runs in a fresh shell process                        | Write `echo "VAR=1" >> "$GITHUB_ENV"` instead of `export`                  |
| **HTTP `403` when pushing or commenting**   | `GITHUB_TOKEN` lacks required write scope                              | Add explicit `permissions:` (e.g., `packages: write`, `pull-requests: write`) |
| **Built files missing in downstream job**   | GitHub does not auto-download artifacts across jobs                    | Upload with `actions/upload-artifact@v7` and fetch with `actions/download-artifact@v8` |
| **Secrets are empty on a contributor PR**   | `pull_request` from external forks blocks secrets for security         | Expected behavior—keep PR CI secret-free or use public test fixtures       |
| **Workflow file doesn't appear or trigger** | File placed outside `.github/workflows/` or syntax error on `on:`      | Place `.yml` directly inside `.github/workflows/` (no nested subfolders)   |

# GitLab CI/CD Configuration: Beginner's Guide & Core Concepts

| Metadata      | Value                      |
| ------------- | -------------------------- |
| Author        | Lyzander Marciano Andrylie |
| Creation Date | Nov 24, 2026               |
| Last Updated  | Nov 24, 2026               |

## References

- [Get Started with GitLab CI/CD](https://docs.gitlab.com/ci/): Official overview of pipelines, runners, variables, and CI/CD components
- [GitLab CI/CD YAML Syntax Reference](https://docs.gitlab.com/ci/yaml/): Complete reference for global, header, and job-level keywords in `.gitlab-ci.yml`
- [Specify When Jobs Run with `rules`](https://docs.gitlab.com/ci/jobs/job_rules/): Conditional execution with `rules:if`, `rules:changes`, `rules:exists`, and avoiding duplicate pipelines
- [GitLab CI/CD `workflow` Keyword](https://docs.gitlab.com/ci/yaml/workflow/): Controlling when pipelines are created and switching cleanly between branch and merge request pipelines
- [Caching in GitLab CI/CD](https://docs.gitlab.com/ci/caching/): Dependency caching, cache keys, fallback keys, and how cache differs from artifacts
- [Job Artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/): Passing build outputs between jobs, expiration policies, and size limits
- [Predefined CI/CD Variables Reference](https://docs.gitlab.com/ci/variables/predefined_variables/): Built-in variables injected by GitLab (`CI_COMMIT_BRANCH`, `CI_PIPELINE_SOURCE`, `CI_JOB_TOKEN`, etc.)
- [Make Jobs Start Earlier with `needs`](https://docs.gitlab.com/ci/yaml/needs/): Directed Acyclic Graph (DAG) job dependencies to bypass strict stage barriers
- [Optimize GitLab CI/CD Configuration Files](https://docs.gitlab.com/ci/yaml/yaml_optimization/): Keeping configurations DRY with `default`, `extends`, `!reference`, and `include`
- [actions.md](../github/actions.md): Companion beginner's guide to GitHub Actions `.github/workflows/` CI/CD configuration
- [config.md](../git/config.md): Git configuration scopes, identity settings, and everyday Git workflow defaults
- [oidc.md](../../auth/oidc.md): Workload OIDC federation for authenticating CI/CD jobs to cloud providers without static secrets

## Description

**GitLab CI/CD** automates building, testing, and deploying code directly from your GitLab repository using a single declarative YAML file (`.gitlab-ci.yml`) at the project root. Instead of manually running test suites and deployment scripts on developer laptops, GitLab detects repository events (pushes, merge requests, tags, or schedules) and executes your defined pipeline inside clean, reproducible environments.

## Concepts

### 1. How GitLab CI/CD Works: Pipelines, Stages, Jobs & Runners

Adding a `.gitlab-ci.yml` file (exact, case-sensitive filename) to the root of a repository automatically enables GitLab CI/CD. Every time a trigger event occurs, GitLab parses the file and schedules work onto execution agents called **Runners**.

- **Core Hierarchy (`Pipeline → Stages → Jobs`)**:
  - **Pipeline**: One complete run of your `.gitlab-ci.yml` triggered by a Git push, merge request, tag, schedule, or manual click.
  - **Stages**: Ordered phases that control *when* groups of jobs run (for example, `build`, then `test`, then `deploy`). If you omit `stages:`, GitLab provides five defaults: `.pre`, `build`, `test`, `deploy`, and `.post`.
  - **Jobs**: Individual units of work (such as `lint`, `unit-test`, or `deploy-prod`). Jobs in the **same stage run in parallel**; the next stage starts only after **all required jobs in the current stage succeed**. A job without a `stage:` keyword defaults to `test`.
- **GitLab Runners (The Workers)**:
  - GitLab Server orchestrates the pipeline, while **GitLab Runners** are separate worker agents (GitLab-hosted or self-hosted) that actually execute job commands.
  - For Docker/Kubernetes executors (the most common setup), the Runner pulls the container `image` you specify, clones your repository into a fresh workspace, runs your shell commands, and streams logs back to GitLab.

#### Interaction

```mermaid
flowchart LR
    Dev["Developer<br>(git push / MR)"] -->|"1. Trigger event"| GL["GitLab Server<br>(Reads .gitlab-ci.yml)"]
    GL -->|"2. Create pipeline"| S1["Stage: build<br>(Jobs run in parallel)"]
    S1 -->|"All succeed"| S2["Stage: test<br>(Jobs run in parallel)"]
    S2 -->|"All succeed"| S3["Stage: deploy"]
    GL -.->|"3. Dispatch jobs"| Runner["GitLab Runner<br>(Pull image -> Clone repo -> Run script)"]
    Runner -.->|"4. Stream logs & status"| GL
```

```yaml
# Minimal .gitlab-ci.yml at the root of your repository
stages:
  - build
  - test
  - deploy

build-app:
  stage: build
  script:
    - echo "Compiling application..."

unit-test:
  stage: test
  script:
    - echo "Running unit tests..."

lint-code:
  stage: test # Runs in parallel with unit-test
  script:
    - echo "Checking code style..."

deploy-app:
  stage: deploy # Runs only if both unit-test and lint-code pass
  script:
    - echo "Deploying application..."
```

---

### 2. Anatomy of a Job: `image`, Scripts, `services` & `tags`

Every top-level YAML key that is not a reserved global keyword (`stages`, `default`, `variables`, `workflow`, `include`, `spec`) and does not start with a dot (`.`) defines a **job**. Every job must include at least `script:` (or `trigger:` for downstream pipelines).

- **Runtime Environment (`image`, `services`, `tags`)**:
  - **`image`**: Container image used to run the job (e.g., `node:22-alpine`, `python:3.12-slim`, `golang:1.23`). Pin specific major/minor versions instead of `latest` so builds stay reproducible.
  - **`services`**: Companion containers started alongside the main job container on the same network (e.g., `postgres:16` or `redis:7` for integration tests). Your script connects to them using the image name as the hostname (`postgres:5432`, `redis:6379`).
  - **`tags`**: Labels used to pick a specific Runner (e.g., `tags: [linux-arm64]` or `tags: [gpu]`). Omit `tags` if you want default shared runners.
- **Script Execution Lifecycle (`before_script` → `script` → `after_script`)**:
  - **`before_script`** and **`script`** run sequentially inside the **same shell session**, so exported variables and `cd` directory changes carry over. If any command returns a non-zero exit code, the job fails immediately.
  - **`after_script`** runs even if `script` fails (unless the job times out), making it useful for cleanup or summary logs—but it runs in a **separate fresh shell** (reset working directory, default 5-minute timeout), and its exit code **does not fail the job**. Files written in `after_script` are still captured before cache and artifact uploads.

| Job Keyword     | Required? | Purpose                                                                 |
| :-------------- | :-------- | :---------------------------------------------------------------------- |
| `script`        | Yes       | Shell commands that perform the job's main task                         |
| `stage`         | No        | Stage the job belongs to (defaults to `test`)                           |
| `image`         | No        | Docker image providing the runtime/toolchain for the job                |
| `before_script` | No        | Setup commands run before `script` in the same shell                    |
| `after_script`  | No        | Cleanup commands run after `script` in a separate shell                 |
| `services`      | No        | Sidecar containers (DBs, caches) linked to the job container            |
| `tags`          | No        | Runner tags required to execute the job                                 |
| `allow_failure` | No        | If `true`, job failure shows a warning instead of failing the pipeline  |
| `retry`         | No        | Automatic retry count (`0`–`2`) for transient network or runner errors  |
| `timeout`       | No        | Maximum job runtime (e.g., `15m`, `1h`) before GitLab aborts it         |

```yaml
stages:
  - test

integration-test:
  stage: test
  image: python:3.12-slim
  services:
    - postgres:16-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: ci_user
    POSTGRES_PASSWORD: ci_password
    DATABASE_URL: "postgresql://ci_user:ci_password@postgres:5432/test_db"
  before_script:
    - pip install --no-cache-dir -r requirements.txt
  script:
    - pytest tests/integration
  after_script:
    - echo "Finished integration tests for $CI_COMMIT_SHORT_SHA"
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

> [!WARNING]
> Because `.gitlab-ci.yml` is YAML, any shell command containing a colon followed by a space (such as `echo "status: ok"` or `curl -H "Accept: application/json" ...`) must be wrapped in quotes, or YAML will misparse it as a key-value mapping.

---

### 3. Variables & Secrets: Custom, Predefined & Protected Settings

CI/CD variables inject configuration values and credentials into jobs as environment variables (`$MY_VAR` in Bash/sh) without hardcoding environment-specific details into scripts.

- **Three Places Variables Come From**:
  1. **`.gitlab-ci.yml` (`variables:`)**: Global or per-job key-value pairs committed to Git—use **only for non-sensitive settings** (app ports, build flags, Node env).
  2. **GitLab UI (`Settings → CI/CD → Variables`)**: Defined at the Project, Group, or Instance level—use for **secrets** (API tokens, deploy keys, registry credentials).
  3. **Predefined Variables**: Automatically populated by GitLab on every pipeline (commit SHA, branch name, MR ID, pipeline trigger source). Never override predefined variable names.
- **Protecting Secrets in GitLab UI**:
  - **Masked**: Replaces the secret value with `[MASKED]` in job logs so accidental `echo` or stack traces do not leak it.
  - **Protected**: Exposes the variable **only** to pipelines running on protected branches (like `main`) or protected tags—preventing untrusted feature branches from reading production credentials.
  - **File Type**: Writes the variable value to a temporary file and sets the variable to that file's path (ideal for kubeconfigs, TLS certs, or JSON key files).
- **Precedence (Highest to Lowest)**:
  - Trigger / manual run / API variables → Project UI variables → Group UI variables → Instance UI variables → Job `variables:` → Global `variables:` → Predefined variables.

| Predefined Variable    | Example Value                  | Common Use Case                                                 |
| :--------------------- | :----------------------------- | :-------------------------------------------------------------- |
| `CI_COMMIT_BRANCH`     | `feature/login`                | Current branch name (empty in MR and tag pipelines)             |
| `CI_DEFAULT_BRANCH`    | `main`                         | Project's default branch (avoids hardcoding `main` vs `master`) |
| `CI_COMMIT_TAG`        | `v1.4.0`                       | Git tag name (only set in tag pipelines)                        |
| `CI_COMMIT_SHORT_SHA`  | `a1b2c3d4`                     | 8-character commit hash for tagging Docker images or builds     |
| `CI_COMMIT_REF_SLUG`   | `feature-login`                | Lowercase, URL-safe branch/tag name for cache keys & preview URLs|
| `CI_PIPELINE_SOURCE`   | `push`, `merge_request_event`  | Identifies what triggered the pipeline (`rules` & `workflow`)   |
| `CI_REGISTRY_IMAGE`    | `registry.gitlab.com/org/app`  | Built-in project Container Registry image path                  |
| `CI_JOB_TOKEN`         | *(masked short-lived token)*   | Ephemeral token scoped to the running job for GitLab API/registry|

```yaml
variables:
  APP_ENV: "production" # Non-sensitive global variable

build-image:
  stage: build
  image: docker:27
  variables:
    IMAGE_TAG: "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
  script:
    # Uses predefined CI_REGISTRY_USER and short-lived CI_JOB_TOKEN
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_JOB_TOKEN" "$CI_REGISTRY"
    - docker build -t "$IMAGE_TAG" .
    - docker push "$IMAGE_TAG"
```

> [!TIP]
> Avoid storing long-lived AWS, GCP, or Azure static keys in CI/CD variables. Use GitLab's `id_tokens:` keyword to mint short-lived OIDC JWTs and exchange them for temporary cloud credentials via Workload Identity Federation (see [oidc.md](../../auth/oidc.md)).

---

### 4. Passing Files & Speeding Up Runs: `artifacts` vs `cache`

Every job starts with a clean repository checkout—files generated in `build` disappear unless you explicitly preserve them. GitLab provides two distinct mechanisms, and choosing the right one prevents slow or flaky pipelines.

| Dimension              | `artifacts`                                                        | `cache`                                                             |
| :--------------------- | :----------------------------------------------------------------- | :------------------------------------------------------------------ |
| **Primary Purpose**    | Pass **build outputs** between jobs in the *same* pipeline         | Speed up **dependency downloads** across *different* pipelines/jobs |
| **Typical Files**      | Compiled binaries (`dist/`, `build/`), JUnit test reports, coverage| `node_modules/`, `.npm/`, `.cache/pip/`, `.m2/`, Go module cache    |
| **Reliability**        | **Guaranteed**: downstream jobs automatically download them        | **Best-effort**: may miss if runner changes or cache expires        |
| **Where Stored**       | Uploaded to GitLab server (downloadable via Web UI & API)          | Stored on Runner local disk or shared object storage (S3 / GCS)     |
| **Expiration**         | Controlled by `expire_in` (set explicitly to save storage)         | Evicted by runner/bucket policy (14 days idle on GitLab.com runners)|
| **Branch Isolation**   | Scoped to the pipeline                                             | Protected and unprotected branches use separate caches by default   |

- **Essential Best Practices & Gotchas**:
  - **Paths Must Stay Inside the Project Directory**: Neither `artifacts:paths` nor `cache:paths` can reference files outside `$CI_PROJECT_DIR` (such as `/root/.npm`). Redirect package managers into a local folder like `.npm/` or `.cache/pip/`.
  - **Key Caches on Lockfiles (`cache:key:files`)**: Hashing `package-lock.json`, `poetry.lock`, or `go.sum` reuses the cache across branches whenever dependencies are unchanged and automatically refreshes it when a dependency updates.
  - **Use `policy: pull` on Read-Only Jobs**: By default (`pull-push`), every job downloads *and* re-uploads the cache. Set `policy: pull` on test/lint jobs that only read dependencies to avoid redundant uploads.
  - **Never Overlap Paths**: Runners restore **cache before artifacts**. Storing the same directory in both causes artifacts to overwrite cached files.
  - **Always Set `artifacts:expire_in`**: Without a short retention window (e.g., `1 day` or `1 week`), build artifacts accumulate and consume storage quota (note: GitLab retains artifacts from the latest successful pipeline per ref by default).

#### Interaction

```mermaid
flowchart LR
    subgraph CacheStore ["Runner / Object Storage (Cache)"]
        C[".npm/ cache<br>(Keyed by package-lock.json)"]
    end

    subgraph Pipeline ["Single Pipeline Run"]
        Build["Job: build<br>(Installs deps -> Builds dist/)"]
        Test["Job: test<br>(Runs tests against dist/)"]
        Deploy["Job: deploy<br>(Deploys dist/)"]
    end

    subgraph GitLabStore ["GitLab Storage (Artifacts)"]
        A["dist/ archive<br>(Expires in 1 week)"]
    end

    C <-->|"pull-push (best-effort)"| Build
    C -->|"pull only"| Test
    Build -->|"Upload artifacts"| A
    A -->|"Auto-download"| Test
    A -->|"Auto-download"| Deploy
```

```yaml
stages:
  - build
  - test

variables:
  npm_config_cache: "$CI_PROJECT_DIR/.npm" # Keep cache inside project directory

build-web:
  stage: build
  image: node:22-alpine
  cache:
    key:
      files:
        - package-lock.json # Busts cache only when lockfile changes
    paths:
      - .npm/
    policy: pull-push
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

test-web:
  stage: test
  image: node:22-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
    policy: pull # Read-only: skips re-uploading cache at job end
  script:
    - npm ci
    - npm test # Can also inspect dist/ downloaded automatically from build-web
```

---

### 5. Controlling Execution: `rules`, `workflow`, Manual Gates & `needs`

Real projects rarely run every job on every commit—you want fast checks on merge requests, path-filtered builds in monorepos, and manual approval before deploying to production.

#### a. Job-Level Conditions (`rules`)

Use `rules:` to decide if and how a job enters a pipeline (it replaces the deprecated `only` and `except` keywords—never mix them in the same job).

- **First Match Wins**: GitLab evaluates each rule from top to bottom and applies the **first matching rule**. If no rule matches, the job is **not added** to the pipeline.
- **Core Rule Clauses**:
  - `if:`: Variable expression (e.g., `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`, `$CI_COMMIT_TAG`, `$CI_PIPELINE_SOURCE == "merge_request_event"`). The variable must be on the left side of `==`, `!=`, or `=~`.
  - `changes:`: Matches only when specified file globs changed (e.g., `frontend/**/*`).
  - `exists:`: Matches only when specific files exist in the repository (e.g., `Dockerfile`).
  - `when:`: Controls execution behavior (`on_success` default, `manual`, `always`, `never`, `delayed`).
- **Manual Gate Gotcha (`allow_failure`)**:
  - Setting `when: manual` **directly on a job** defaults to `allow_failure: true` (optional job; pipeline succeeds without clicking it).
  - Setting `when: manual` **inside `rules:`** defaults to `allow_failure: false` (blocking gate; pipeline pauses in `blocked` state until clicked). Add `allow_failure: true` explicitly inside the rule if you want an optional manual job.

#### b. Preventing Duplicate Pipelines (`workflow:rules`)

A common beginner bug occurs when adding `rules:` to jobs: pushing a commit to a branch with an open Merge Request triggers **two pipelines at once** (a branch push pipeline *and* a merge request pipeline).

- Top-level `workflow:rules` runs **before** any job rules and decides whether to create a pipeline at all.
- The standard pattern below runs MR pipelines once an MR is open, branch pipelines when no MR is open, and tag pipelines on release tags—eliminating duplicates.

#### c. Faster Pipelines with `needs` (DAG Execution)

By default, jobs in stage 2 wait until *every* job in stage 1 finishes. The `needs:` keyword lets a job start the moment its specific upstream jobs finish, forming a **Directed Acyclic Graph (DAG)**.

- **`needs: [build-frontend]`**: Starts immediately after `build-frontend` succeeds, even if `build-backend` is still running.
- **`needs: []`**: Starts immediately at pipeline creation without waiting for earlier stages (ideal for linters or secret scanners that inspect source code directly).
- **Artifact Gotcha with `needs:`**: Normally a job downloads artifacts from *all* jobs in earlier stages. Once you add `needs:`, GitLab downloads artifacts **only from the jobs listed in `needs:`** (or set `artifacts: false` inside a `needs` entry to skip downloading them).

#### Interaction

```mermaid
flowchart LR
    Start["Pipeline Start"] --> Lint["lint-code<br>(stage: test, needs: [])<br>Starts immediately"]
    Start --> BuildWeb["build-web<br>(stage: build)"]
    Start --> BuildAPI["build-api<br>(stage: build, slower)"]

    BuildWeb -->|"needs: [build-web]"| TestWeb["test-web<br>(stage: test)<br>Starts without waiting for build-api"]
    BuildAPI -->|"needs: [build-api]"| TestAPI["test-api<br>(stage: test)"]

    TestWeb --> Deploy["deploy-prod<br>(stage: deploy, manual gate)"]
    TestAPI --> Deploy
```

```yaml
workflow:
  rules:
    # 1. Run MR pipelines for open merge requests
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    # 2. Skip branch push pipeline if an MR is already open for this branch
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    # 3. Run branch pipelines (when no MR is open) and tag pipelines
    - if: '$CI_COMMIT_BRANCH || $CI_COMMIT_TAG'

stages:
  - build
  - test
  - deploy

lint-code:
  stage: test
  needs: [] # Runs immediately alongside build jobs
  script:
    - npm run lint

build-web:
  stage: build
  rules:
    - changes:
        - web/**/*
  script:
    - npm --prefix web run build
  artifacts:
    paths:
      - web/dist/

test-web:
  stage: test
  needs:
    - job: build-web
      optional: true # Prevents error if build-web was skipped by rules:changes
  rules:
    - changes:
        - web/**/*
  script:
    - npm --prefix web test

deploy-prod:
  stage: deploy
  environment:
    name: production
    url: https://app.example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual # Blocks until clicked (allow_failure defaults to false in rules)
      allow_failure: true # Makes manual deploy optional so pipeline still passes
  script:
    - ./scripts/deploy.sh production
```

---

### 6. Keeping Config DRY: `default`, Hidden Jobs (`extends`), `!reference` & `include`

As your repository grows beyond a few jobs, duplicating `image`, `cache`, `before_script`, and `rules` makes updates error-prone. GitLab offers four built-in reuse mechanisms.

| Mechanism            | Scope                | How Merging Works                                                         | Best Used For                                          |
| :------------------- | :------------------- | :------------------------------------------------------------------------ | :----------------------------------------------------- |
| **`default:`**       | All jobs in pipeline | Job-level keyword **replaces** the default (arrays do not merge)          | Repo-wide `image`, `retry`, `tags`, or `before_script` |
| **Hidden job + `extends`** | Same or included files | Deep-merges maps/hashes; overrides arrays (`script`, `before_script`) | Reusable base job templates (`.node-job`, `.deploy-base`)|
| **`!reference`**     | Same or included files | Injects a specific array/section from another job inline                  | Composing shared `before_script` or `rules` lists      |
| **`include:`**       | Across files / repos | Merges external YAML files into `.gitlab-ci.yml` at pipeline creation     | Splitting big configs (`local`), shared templates (`project`), CI/CD Catalog (`component`) |

- **Hidden Jobs Start with a Dot (`.`)**: Naming a job `.base-node` tells GitLab never to run it directly; it exists purely as a template for `extends` or `!reference`.
- **Prefer `extends` and `!reference` Over Raw YAML Anchors (`&`/`*`)**: Standard YAML anchors only work inside a single file, whereas `extends` and `!reference` work seamlessly across `include`d files.

```yaml
# Split large pipelines into modular files
include:
  - local: ".gitlab/ci/lint.yml"

default:
  image: node:22-alpine
  retry: 1

# Hidden template job (never executed on its own)
.node-base:
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
    policy: pull
  before_script:
    - npm ci --cache .npm --prefer-offline

unit-test:
  stage: test
  extends: .node-base
  script:
    - npm run test:unit

e2e-test:
  stage: test
  extends: .node-base
  before_script:
    # Reuse .node-base's before_script and append an extra step
    - !reference [.node-base, before_script]
    - npx playwright install --with-deps chromium
  script:
    - npm run test:e2e
```

---

### 7. Complete Beginner Starter Pipeline & Debugging Checklist

This end-to-end `.gitlab-ci.yml` combines every core concept into a clean starter template for a Node.js web service: duplicate-free `workflow`, dependency caching, `needs: []` fast linting, build artifacts, automatic staging deploys, and a manual production gate.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_COMMIT_BRANCH || $CI_COMMIT_TAG'

stages:
  - build
  - test
  - deploy

default:
  image: node:22-alpine

variables:
  npm_config_cache: "$CI_PROJECT_DIR/.npm"

.node-cache-read:
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
    policy: pull

build-app:
  stage: build
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
    policy: pull-push
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

lint:
  stage: test
  needs: [] # Runs immediately in parallel with build-app
  extends: .node-cache-read
  script:
    - npm ci
    - npm run lint

unit-test:
  stage: test
  needs: [build-app]
  extends: .node-cache-read
  script:
    - npm ci
    - npm test -- --ci

deploy-staging:
  stage: deploy
  needs: [build-app, lint, unit-test]
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
  script:
    - echo "Deploying dist/ ($CI_COMMIT_SHORT_SHA) to staging..."

deploy-production:
  stage: deploy
  needs: [build-app, deploy-staging]
  environment:
    name: production
    url: https://app.example.com
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual
      allow_failure: true
  script:
    - echo "Deploying dist/ ($CI_COMMIT_SHORT_SHA) to production..."
```

#### Validation & Common Beginner Pitfalls

Always validate edits in **GitLab UI → Build → Pipeline editor** before pushing broken commits:

- **Validate Tab (CI Lint)**: Checks YAML syntax, unknown keywords, and simulates how pipelines behave on push or MR events.
- **Full Configuration Tab**: Displays the final merged YAML after all `include`, `extends`, and `!reference` directives are expanded—invaluable when debugging why a job inherited unexpected settings.
- **Visualize Tab**: Renders the stage and `needs` graph so you can verify parallelization and dependencies visually.

| Symptom                                   | Most Likely Cause                                                      | Fix                                                                        |
| :---------------------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| **Two pipelines run on every MR push**    | Job has `rules:` without top-level `workflow:rules`                    | Add `workflow:rules` blocking branch push pipelines when `$CI_OPEN_MERGE_REQUESTS` is set |
| **Job stuck in `Pending` forever**        | `tags:` does not match any active/online Runner                        | Remove `tags:` to use shared runners, or verify runner tags in CI/CD settings |
| **YAML syntax error on a shell command**  | Unquoted `: ` inside `script:` (e.g., `curl -H "Auth: Bearer ..."`)    | Wrap the command string in single or double quotes                         |
| **Downstream job missing built files**    | Forgot `artifacts:paths` on build job, or `needs:` omitted that job    | Add `artifacts:paths` on producer and include producer in `needs:`         |
| **Secret variable is empty in feature MR**| Variable is marked **Protected** in Project Settings                   | Expected security behavior—test on a protected branch or use non-prod staging creds |
| **`after_script` didn't see `export VAR`**| `after_script` executes in a separate fresh shell                      | Write shared data to a file in `$CI_PROJECT_DIR` during `script`           |

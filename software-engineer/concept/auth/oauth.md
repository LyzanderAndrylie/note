# OAuth 2.0, OAuth 2.1, and Modern Authorization Architectures

A technical guide and engineering reference on the OAuth authorization framework, grant flows, cryptographic extensions (PKCE, DPoP), OpenID Connect (OIDC) identity federation, security threat models, and architectural patterns.

## References

- [RFC 6749: The OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749): Core authorization framework, roles, client types, and authorization grants.
- [RFC 6750: The OAuth 2.0 Authorization Framework - Bearer Token Usage](https://datatracker.ietf.org/doc/html/rfc6750): HTTP header, request body, and URI query parameter bearer token usage.
- [RFC 7636: Proof Key for Code Exchange (PKCE)](https://datatracker.ietf.org/doc/html/rfc7636): Mitigating authorization code interception attacks on public clients.
- [RFC 7662: OAuth 2.0 Token Introspection](https://datatracker.ietf.org/doc/html/rfc7662): Back-channel protocol enabling Resource Servers to query the active state and metadata of a token.
- [RFC 8252: OAuth 2.0 for Native Apps (AppAuth)](https://datatracker.ietf.org/doc/html/rfc8252): Best practices for native application authorization.
- [RFC 8628: OAuth 2.0 Device Authorization Grant](https://datatracker.ietf.org/doc/html/rfc8628): Authorization flow for browserless and input-constrained devices.
- [RFC 9449: Demonstrating Proof-of-Possession (DPoP)](https://datatracker.ietf.org/doc/html/rfc9449): Application-level sender-constraining for OAuth tokens.
- [The OAuth 2.1 Authorization Framework (Draft)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1): Consolidation of OAuth 2.0 security best current practices.
- [OpenID Connect Core 1.0 Specification](https://openid.net/specs/openid-connect-core-1_0.html): Identity federation and profile retrieval on top of OAuth 2.0.
- [jwt.md](./jwt.md): Compact JSON claims representations, JOSE signatures (JWS), and encryption (JWE).
- [oidc.md](./oidc.md): OpenID Connect identity layer, ID Token validation, discovery, and workload OIDC federation.
- [tls.md](./tls.md): Transport Layer Security, mTLS sender-constrained tokens, and certificate validation.
- [workload_identity.md](../kubernetes/workload_identity.md): RFC 8693 OAuth 2.0 token exchange and OIDC federation from Kubernetes to AWS STS and Google STS.
- [common_vulnerabilities.md](../security/common_vulnerabilities.md): CSRF, XSS, SSRF, SQL injection, and access control threat mechanisms and mitigations.

---

## 1. High-Level Concept: The Delegation Problem

Before OAuth, third-party integrations relied on the **"Password Anti-Pattern"**: a user gave their primary credentials (username and password) directly to a third-party application so it could access their account on another service.

```mermaid
flowchart LR
    subgraph AntiPattern ["The Password Anti-Pattern (Pre-OAuth)"]
        User1["User"] -->|"Provides raw username & password"| ThirdParty1["Third-Party App"]
        ThirdParty1 -->|"Logs in as User"| Service1["Protected API / Service"]
    end
```

### Critical Flaws of the Anti-Pattern

1. **Over-privileged Access**: The third-party application had full access to the user's entire account (no scoped permissions).
2. **Indiscriminate Lifetime**: Access could only be revoked by changing the user's primary password, breaking all other integrated apps.
3. **Compromise Blast Radius**: A compromise of the third-party client exposed raw user credentials.
4. **No MFA Compatibility**: Third-party automated scripts could not easily satisfy multi-factor authentication (MFA) challenges.

### The OAuth Solution: Delegated Authorization

OAuth 2.0 ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)) solves this by introducing an authorization intermediary and replacing direct credential sharing with **scoped, revocable, short-lived tokens**.

```mermaid
sequenceDiagram
    autonumber
    actor RO as Resource Owner<br/>(End User)
    participant Web as Web Browser<br/>(User-Agent)
    participant Client as Client Application<br/>(SPA, Mobile App, Backend Service)
    participant AS as Authorization Server<br/>(IdP / OAuth AS)
    participant RS as Resource Server<br/>(Protected API)

    RO->>Web: Uses Client Application
    Web->>Client: Requests protected action
    Client-->>Web: Redirects user to IdP Web (requested scope)
    Web->>AS: Opens IdP Consent Page (scope=...)
    RO->>AS: Authenticates & authorizes specific scope
    AS-->>Web: Redirects back with Authorization Grant
    Web->>Client: Delivers Authorization Grant
    Client->>AS: Exchanges Grant for Access Token
    AS-->>Client: Issues Scoped Access Token
    Client->>RS: Presents Access Token (Bearer)
    RS-->>Client: Returns Protected Resource
```

---

## 2. Core OAuth 2.0 Roles and Terminology

### 2.1 The Four Protocol Roles

| Role                     | RFC 6749 Designation   | Description                                                                                     | Example                                   |
| :----------------------- | :--------------------- | :---------------------------------------------------------------------------------------------- | :---------------------------------------- |
| **Resource Owner**       | `resource_owner`       | The entity capable of granting access to a protected resource (usually a human user).           | A person using a web app.                 |
| **Client**               | `client`               | The software application requesting access to resources on behalf of the Resource Owner.        | A web dashboard, mobile app, or CLI tool. |
| **Authorization Server** | `authorization_server` | The server that authenticates the Resource Owner, gathers consent, and issues security tokens.  | Auth0, Okta, Keycloak, Google Identity.   |
| **Resource Server**      | `resource_server`      | The server hosting the protected resources and accepting access tokens to fulfill API requests. | GitHub REST API, internal microservices.  |

> [!NOTE]
> The Authorization Server and Resource Server can reside within the same physical application or be separated into independent distributed microservices.

---

### 2.2 Client Classification

OAuth strictly separates clients by their ability to protect credentials:

```mermaid
mindmap
  root((OAuth Client Types))
    Confidential Clients
      Secure Server Backend
      Can protect client_secret
      Node.js / Go / Java / Python Web Apps
      Machine-to-Machine daemons
    Public Clients
      Runs on User Device / Browser
      CANNOT protect client_secret
      Single Page Applications (React, Vue)
      Native Mobile Apps (iOS, Android)
      Desktop / CLI Apps
```

- **Confidential Client**: Executes on a secure server environment with restricted access where secrets (such as a `client_secret` or private signing key) cannot be extracted by unauthorized parties.
- **Public Client**: Executes on an end-user device or inside a web browser (e.g., Single Page Apps, iOS/Android apps). Any embedded secret can be decompiled, inspected in dev tools, or extracted via network proxies. **Public clients must never be issued static client secrets.**

---

### 2.3 Artifacts: Tokens, Scopes, and Context Parameters

```mermaid
classDiagram
    class AccessToken {
        +String value (JWT or Opaque)
        +Int expiresIn
        +String tokenType (Bearer / DPoP)
        +String scope
    }
    class RefreshToken {
        +String value
        +String rotationFamily
        +Boolean isRevoked
    }
    class IDToken {
        +String iss
        +String sub
        +String aud
        +Int exp
        +String nonce
    }
    class ProtocolState {
        +String state (CSRF mitigation)
        +String codeVerifier (PKCE)
        +String codeChallenge (PKCE)
    }
```

- **Access Token**: A credential representing authorization granted to the client. It can be:
  - **Opaque (Reference Token)**: A random string serving as a database lookup key; contains no readable claims and requires **token introspection** ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662)) by the Resource Server against the Authorization Server's `/introspect` endpoint to verify validity and retrieve metadata (see [Section 4.6](#46-token-introspection-rfc-7662)).
  - **Structured (Value Token / JWT)**: Self-contained cryptographic token (`RFC 7519`) containing signed claims (`sub`, `aud`, `exp`, `scope`), validated offline using the Authorization Server's public keys (`JWKS`).
- **Refresh Token**: A long-lived credential used exclusively to obtain fresh access tokens when current access tokens expire, without re-prompting the user.
- **ID Token (OIDC Extension)**: A signed JWT representing identity assertions about the user's authentication event (identity layer, not access authorization).
- **Scope**: A space-delimited list of strings defining the granular boundaries of permissions requested (e.g., `read:reports write:profile`).
- **`state` Parameter**: An opaque, unguessable value generated by the client and sent to the `/authorize` endpoint. The Authorization Server returns it unmodified to the redirect URI. It binds the authorization response to the client session, preventing Cross-Site Request Forgery (CSRF).

---

## 3. Flow Selection Matrix

OAuth 2.0 defines several grant types. Choosing the correct flow depends on the client type, user involvement, and device capabilities:

```mermaid
flowchart TD
    Start["What type of client application are you building?"] --> Q1{"Is an end-user<br/>interactively logging in?"}

    Q1 -- No --> M2M["Client Credentials Grant<br/>(Machine-to-Machine, Daemons, Cron Jobs)"]

    Q1 -- Yes --> Q2{"Does the device have<br/>a full browser & rich input?"}

    Q2 -- No (Smart TV, CLI, IoT) --> Device["Device Authorization Grant<br/>(RFC 8628 - Device Flow)"]

    Q2 -- Yes --> Q3{"Is the client a Confidential<br/>Backend or a Public Client?"}

    Q3 -- Confidential Backend --> AuthCode["Authorization Code Flow<br/>(+ PKCE recommended / OAuth 2.1 required)"]
    Q3 -- Public Client (SPA / Mobile) --> PKCE["Authorization Code Flow with PKCE<br/>(RFC 7636)"]
```

---

## 4. Grant Types and Execution Flows

### 4.1 Authorization Code Flow (Traditional Confidential Clients)

Used by server-rendered applications (e.g., Next.js backend, Spring Boot, Django, Ruby on Rails) where the client possesses a `client_secret` securely stored on a backend server.

```mermaid
sequenceDiagram
    autonumber
    actor User as Resource Owner
    participant Browser as User-Agent (Browser)
    participant Client as Client Web Server
    participant AS as Authorization Server
    participant RS as Resource Server

    User->>Browser: Click "Sign in with OAuth"
    Browser->>Client: GET /login
    Client-->>Browser: 302 Redirect to AS /authorize<br/>(?response_type=code&client_id=CLIENT_ID&redirect_uri=CALLBACK&scope=read:user&state=RANDOM_STATE)
    Browser->>AS: GET /authorize
    AS->>User: Render Login & Consent Screen
    User->>AS: Enter Credentials & Authorize App
    AS-->>Browser: 302 Redirect to Client CALLBACK<br/>(?code=AUTH_CODE&state=RANDOM_STATE)
    Browser->>Client: GET /callback?code=AUTH_CODE&state=RANDOM_STATE
    Note over Client: Verify state matches session state
    Client->>AS: POST /token (Back-Channel)<br/>(grant_type=authorization_code, code=AUTH_CODE, redirect_uri, client_id, client_secret)
    AS->>AS: Authenticate client_secret & validate code
    AS-->>Client: 200 OK (access_token, refresh_token, expires_in)
    Client->>RS: GET /api/user (Header: Authorization: Bearer ACCESS_TOKEN)
    RS-->>Client: 200 OK (User Data)
    Client-->>Browser: Session established (HttpOnly Cookie)
```

#### Key Mechanics:

- **Two Channels**:
  1. **Front-Channel** (Steps 2–7): Passes through the user's browser via redirects. Potentially exposed to browser history, proxy logs, and URL manipulation.
  2. **Back-Channel** (Steps 9–11): Direct, encrypted HTTPS connection between the Client server and the Authorization Server. The `client_secret` is never exposed to the browser.
- **Single-Use Authorization Code**: The temporary code returned in the front-channel has a short time-to-live (typically 30–60 seconds) and is invalidated immediately upon first use.

---

### 4.2 Authorization Code Flow with PKCE (Proof Key for Code Exchange)

PKCE ([RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636), pronounced "pixie") was engineered to protect **public clients** (SPAs, mobile apps) that lack a `client_secret` from **Authorization Code Interception Attacks**.

#### The Vulnerability PKCE Solves: Code Interception

On mobile devices and desktops, apps register custom URI schemes (e.g., `myapp://oauth-callback`). A malicious app installed on the same device could register that identical custom scheme, intercept the incoming authorization code from the redirect, and exchange it for tokens at `/token` if no client secret is required.

```mermaid
flowchart TD
    subgraph InterceptionThreat ["Code Interception Attack (Without PKCE)"]
        Browser["System Browser"] -->|"302 Redirect: myapp://callback?code=XYZ"| OS["Operating System Router"]
        OS -.->|"Attacker registered same scheme!"| MaliciousApp["Malicious App"]
        MaliciousApp -->|"POST /token (code=XYZ, client_id=123)"| AS["Authorization Server"]
        AS -->|"Returns Access Token"| MaliciousApp
    end
```

#### The PKCE Solution: Dynamic Cryptographic Proof

Instead of relying on a static secret, the client dynamically generates a one-time cryptographic secret for each authentication request:

1. **Code Verifier**: A cryptographically random string using characters `[A-Z]`, `[a-z]`, `[0-9]`, `-`, `.`, `_`, `~`, with a minimum length of 43 characters and maximum of 128 characters:
   $$\text{code\_verifier} \in [A\text{-}Za\text{-}z0\text{-}9\text{-}.\_\sim]^{43..128}$$
2. **Code Challenge**: The Base64URL-encoded SHA-256 hash of the verifier:
   $$\text{code\_challenge} = \text{BASE64URL-ENCODE}(\text{SHA-256}(\text{code\_verifier}))$$
   $$\text{code\_challenge\_method} = \text{"S256"}$$

```mermaid
sequenceDiagram
    autonumber
    actor User as Resource Owner
    participant App as Public Client (SPA / Mobile)
    participant AS as Authorization Server
    participant RS as Resource Server

    Note over App: 1. Generate code_verifier (random high-entropy string)<br/>2. Compute code_challenge = BASE64URL(SHA256(code_verifier))
    App->>AS: GET /authorize?response_type=code<br/>&client_id=PUBLIC_APP<br/>&redirect_uri=APP_CALLBACK<br/>&code_challenge=CHALLENGE_HASH<br/>&code_challenge_method=S256<br/>&state=STATE
    AS->>AS: Store code_challenge & method bound to pending request
    AS->>User: Authenticate & Gather Consent
    User->>AS: Approves
    AS-->>App: Redirect with authorization code (?code=AUTH_CODE&state=STATE)

    Note over App: Client now provides the original unhashed code_verifier!
    App->>AS: POST /token<br/>(grant_type=authorization_code, code=AUTH_CODE, client_id=PUBLIC_APP, redirect_uri=APP_CALLBACK, code_verifier=RAW_VERIFIER)

    AS->>AS: Calculate SHA256(RAW_VERIFIER)<br/>Compare with stored code_challenge
    alt Hash Matches
        AS-->>App: 200 OK (access_token, refresh_token)
        App->>RS: Request Data with Bearer Token
        RS-->>App: 200 OK (Protected Resource)
    else Hash Mismatch or Missing Verifier
        AS-->>App: 400 Bad Request (invalid_grant)
    end
```

> [!IMPORTANT]
> **Why the Attacker is Blocked**: Even if a malicious app intercepts the `code` from the redirect URI, it cannot exchange it at `/token` because it does not know the raw `code_verifier`, which never left the memory space of the legitimate client application.
>
> In **OAuth 2.1**, PKCE is **mandatory for all clients**, including confidential clients, mitigating authorization code injection attacks across all topologies.

---

### 4.3 Client Credentials Flow (Machine-to-Machine)

Used when applications communicate directly without any human user present (microservice-to-microservice, background daemons, scheduled cron jobs).

```mermaid
sequenceDiagram
    autonumber
    participant Daemon as Service A (Client)
    participant AS as Authorization Server
    participant API as Service B (Resource Server)

    Note over Daemon: Needs access to read telemetry data
    Daemon->>AS: POST /token<br/>grant_type=client_credentials<br/>&client_id=SERVICE_A_ID<br/>&client_secret=SERVICE_A_SECRET<br/>&scope=telemetry:read
    AS->>AS: Authenticate Service A credentials & verify scope
    AS-->>Daemon: 200 OK (access_token, token_type=Bearer, expires_in=3600)
    Note over Daemon: No refresh token is issued (unnecessary for M2M)
    Daemon->>API: GET /metrics (Authorization: Bearer ACCESS_TOKEN)
    API->>API: Validate token signature & scope
    API-->>Daemon: 200 OK (Metrics Payload)
```

#### Key Characteristics:

- **No Resource Owner Interaction**: The client acts on its own behalf (`RFC 6749 §4.4`).
- **No Refresh Tokens**: Since the client can authenticate unattended using its pre-provisioned credentials, issuing refresh tokens creates unnecessary state. When the access token expires, the client simply calls `/token` again.
- **Client Authentication Methods (Confidential Clients Only)**: The client authenticates to `/token` using a **pre-registered static credential** (never safe for public clients like SPAs or mobile apps):
  - **Shared Symmetric Secret (`client_secret`)**: Both the client and AS hold the same secret, sent via HTTP Basic Auth (`client_secret_basic`), POST body (`client_secret_post`), or used as an HMAC key (`client_secret_jwt`).
  - **Asymmetric Key Assertion (`private_key_jwt`, [RFC 7523](https://datatracker.ietf.org/doc/html/rfc7523))**: Only the client's **public key** (or JWKS URL) is pre-registered with the AS; the client keeps the **private key** and sends a short-lived signed JWT (`client_assertion`) instead of transmitting a shared secret.
  - **Mutual TLS (`mTLS`, [RFC 8705](https://datatracker.ietf.org/doc/html/rfc8705))**: The client authenticates at the TLS layer with a client X.509 certificate (and can bind the resulting access token to that certificate).
- **Optional Sender-Constraining**: Client authentication only proves the caller's identity to the **Authorization Server**; layering **DPoP** ([Section 7.3](#73-securing-bearer-tokens-dpop-rfc-9449)) or **mTLS** also binds the returned access token so a leaked token cannot be replayed against the Resource Server.

---

### 4.4 Device Authorization Flow (RFC 8628)

Designed for internet-connected devices that either lack a browser or have severe input constraints (Apple TV, smart TVs, CLI terminals, gaming consoles).

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant Device as Smart TV / CLI Tool
    participant Phone as User Phone / PC Browser
    participant AS as Authorization Server

    Device->>AS: POST /device/code (client_id=TV_APP, scope=stream:video)
    AS-->>Device: 200 OK<br/>{device_code: "DC_998877", user_code: "WDJB-HGTR", verification_uri: "https://auth.example.com/activate", interval: 5}

    Device->>User: Display message: "Visit https://auth.example.com/activate and enter code: WDJB-HGTR"

    par Polling Loop
        loop Every `interval` seconds (5s)
            Device->>AS: POST /token (grant_type=urn:ietf:params:oauth:grant-type:device_code, device_code="DC_998877", client_id=TV_APP)
            AS-->>Device: 400 Bad Request (error: authorization_pending)
        end
    and User Authorization
        User->>Phone: Navigates to activation page
        Phone->>AS: GET /activate
        User->>Phone: Types code "WDJB-HGTR" & clicks Authorize
        Phone->>AS: Authenticate User & Approve Device Request
        AS->>AS: Mark device_code as APPROVED
    end

    Device->>AS: Next poll POST /token
    AS-->>Device: 200 OK (access_token, refresh_token)
    Device->>Device: Store tokens and proceed to main UI
```

#### Key Mechanics:

- **Rate-Limitation**: The AS provides a polling `interval` (e.g., 5 seconds). If the device polls faster than the allowed rate, the AS returns error `slow_down`, and the device must back off by increasing its polling interval by at least 5 seconds.

---

### 4.5 Refresh Token Rotation & Reuse Detection

Access tokens must be short-lived (e.g., 5–15 minutes) to limit exposure if stolen. Refresh tokens are longer-lived (days to months). If a refresh token is compromised on a public client, an attacker could maintain persistent access.

To neutralize this, **Refresh Token Rotation (RTR)** issues a brand-new refresh token every time the client consumes one, invalidating the old one immediately.

```mermaid
sequenceDiagram
    autonumber
    participant Client as Legit Client
    participant AS as Authorization Server
    participant Attacker as Attacker

    Note over Client,AS: Initial State: Client holds Refresh Token R1
    Client->>AS: POST /token (grant_type=refresh_token, refresh_token=R1)
    AS->>AS: Invalidate R1.<br/>Issue Access Token A2 + Refresh Token R2.
    AS-->>Client: 200 OK (access_token=A2, refresh_token=R2)

    Note over Attacker: Attacker previously exfiltrated R1!
    Attacker->>AS: POST /token (grant_type=refresh_token, refresh_token=R1)
    AS->>AS: REUSE DETECTED!<br/>R1 was already redeemed!
    Note over AS: Token Family Compromise Detected
    AS->>AS: Revoke R2, A2, and all tokens in this session hierarchy
    AS-->>Attacker: 400 Bad Request (invalid_grant)

    Note over Client: Next time legitimate client tries to use R2
    Client->>AS: POST /token (refresh_token=R2)
    AS-->>Client: 401 Unauthorized (Session terminated due to breach)
    Client->>Client: Force user to re-authenticate with full credentials
```

---

### 4.6 Token Introspection (RFC 7662)

When a Resource Server receives an **opaque (reference) access token**, it cannot decode claims or verify signatures locally. Even with structured JWTs, a Resource Server may need to confirm in real time that a token has not been revoked before its `exp` timestamp.

**OAuth 2.0 Token Introspection ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662))** solves this by defining a back-channel `POST /introspect` endpoint on the Authorization Server where an authorized Resource Server queries the current state (`active`) and metadata (`scope`, `sub`, `client_id`, `exp`, `token_type`) of a token.

```mermaid
sequenceDiagram
    autonumber
    participant Client as Client Application
    participant RS as Resource Server<br/>(or API Gateway)
    participant AS as Authorization Server<br/>(/introspect)

    Client->>RS: GET /api/orders<br/>(Authorization: Bearer OPAQUE_ACCESS_TOKEN)
    Note over RS: Token is opaque — cannot validate locally
    RS->>AS: POST /introspect (Back-Channel, RS authenticated)<br/>(token=OPAQUE_ACCESS_TOKEN&token_type_hint=access_token)
    AS->>AS: Look up token state, expiry, and revocation status
    alt Token is valid & active
        AS-->>RS: 200 OK<br/>{"active": true, "scope": "read:orders", "sub": "usr_123", "exp": 1795245200}
        RS->>RS: Verify active == true and required scope
        RS-->>Client: 200 OK (Protected Resource)
    else Token is expired, revoked, or unknown
        AS-->>RS: 200 OK<br/>{"active": false}
        RS-->>Client: 401 Unauthorized (invalid_token)
    end
```

#### Key Mechanics & Architectural Trade-offs:

- **Authenticated Caller Requirement**: The `/introspect` endpoint must not be public; the Resource Server must authenticate (e.g., HTTP Basic Auth with `client_id`/`client_secret`, mTLS, or a client assertion) so attackers cannot probe tokens or harvest user metadata (`RFC 7662 §2.1`).
- **Uniform Inactive Response (`active: false`)**: For expired, revoked, malformed, or nonexistent tokens, the Authorization Server returns HTTP `200 OK` with `{"active": false}` and omits all other claims to avoid leaking token validity details (`RFC 7662 §2.2`).
- **Request & Response Parameters**:
  - **Request** (`application/x-www-form-urlencoded`): `token` (required) and optional `token_type_hint` (`access_token` or `refresh_token`) to help the AS optimize store lookups.
  - **Response** (`application/json`): `active` (required boolean), plus optional metadata such as `scope`, `client_id`, `username`, `token_type`, `exp`, `iat`, `sub`, `aud`, `iss`, and `jti`.
- **Introspection vs. Offline JWT Validation**:
  - **Pros**: Enables **immediate revocation** (revoked tokens fail introspection on the very next request) and **zero claim leakage** to public clients (used heavily at API gateways in the **Phantom Token Pattern** — see [jwt.md](./jwt.md#strategy-d-the-phantom-token-pattern-perimeter-translation)).
  - **Cons**: Adds a synchronous network call and latency overhead to API requests and makes the Authorization Server a runtime availability dependency unless the Resource Server caches introspection results briefly (which trades instant revocation for lower latency).

---

## 5. Deprecated and Forbidden Grants in Modern OAuth

OAuth 2.1 officially deprecates and removes two flows that were widespread in legacy OAuth 2.0 implementations:

```mermaid
flowchart LR
    subgraph Forbidden ["Removed in OAuth 2.1"]
        direction TB
        F1["Implicit Grant<br/>(response_type=token)"]
        F2["Resource Owner Password Credentials<br/>(ROPC: grant_type=password)"]
    end
```

### 5.1 Why the Implicit Flow is Removed

In the legacy Implicit Flow, the Authorization Server directly appended the `access_token` to the URL fragment (`#access_token=...`) in the redirect to the browser:

- **URL Leakage**: Access tokens were exposed in browser history, HTTP `Referer` headers, proxy logs, and open redirect targets.
- **No Client Authentication**: No opportunity to verify caller identity.
- **No Refresh Tokens**: Refresh tokens could not be securely issued via URL hash fragments.
- **Modern Alternative**: Use **Authorization Code Flow with PKCE**.

### 5.2 Why Resource Owner Password Credentials (ROPC) is Removed

ROPC accepted the user's plain-text `username` and `password` in a `POST /token` payload:

- **Preserved Credential Sharing**: Defeated OAuth's foundational principle of never exposing user credentials to client applications.
- **Incompatible with MFA and SSO**: If the identity provider enforces WebAuthn, FIDO2, SMS OTP, or SAML redirects, ROPC breaks.
- **Expands Threat Surface**: Any client handling plain-text credentials becomes a target for credential dumping and memory scraping.

---

## 6. OAuth 2.0 vs. OpenID Connect (OIDC)

A frequent point of architectural confusion is conflating **Authorization** with **Authentication**.

```mermaid
flowchart TD
    subgraph Comparison ["Authentication vs Authorization"]
        OIDC["OpenID Connect (OIDC)<br/><b>Authentication</b><br/>'Who is the user?'<br/>Artifact: ID Token (JWT)"]
        OAuth["OAuth 2.0<br/><b>Authorization</b><br/>'What permissions does the client have?'<br/>Artifact: Access Token"]
    end
    OIDC -->|"Extends and sits on top of"| OAuth
```

### The Hotel Keycard Analogy

- **OIDC (ID Token)**: Your **Passport or Driver's License**. It proves _who you are_, contains your name, issuance authority, and picture. You present it at the front desk to prove your identity.
- **OAuth (Access Token)**: The **Hotel Keycard**. It does not care what your name is or what your government ID says; the door lock only checks: _Does this keycard have permission to unlock Room 402 until 11:00 AM?_

### Technical Differences Matrix

| Dimension                    | OAuth 2.0 ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)) | OpenID Connect Core 1.0                                    |
| :--------------------------- | :-------------------------------------------------------------------- | :--------------------------------------------------------- |
| **Primary Purpose**          | **Authorization** (Access delegation).                                | **Authentication** (Identity verification + SSO).          |
| **Target Audience of Token** | The **Resource Server** (API).                                        | The **Client Application**.                                |
| **Key Artifact**             | **Access Token** (Opaque or JWT).                                     | **ID Token** (Always a cryptographically signed JWT).      |
| **Standardized Format?**     | No specification for token contents in RFC 6749.                      | Strictly standardized JSON claims structure.               |
| **Identity Claims**          | None guaranteed (custom scopes required).                             | Standard claims: `sub`, `name`, `email`, `email_verified`. |
| **Discovery Mechanism**      | None defined in core RFC.                                             | Discovery Endpoint: `/.well-known/openid-configuration`.   |
| **User Info Profile API**    | Not standardized.                                                     | Standardized `/userinfo` endpoint.                         |

#### Anatomical Structure of an OIDC ID Token:

```json
{
  "iss": "https://auth.company.com/",
  "sub": "usr_9988224411",
  "aud": "my-web-app-client-id",
  "exp": 1727220000,
  "iat": 1727216400,
  "auth_time": 1727216390,
  "nonce": "n-0S6_WzA2Mj",
  "email": "alex.dev@company.com",
  "email_verified": true
}
```

---

## 7. Security Threat Models & Attack Vectors

```mermaid
mindmap
  root((OAuth Attack Vectors))
    Redirect URI Manipulation
      Wildcard subdomain hijacking
      Path traversal open redirect
    Cross-Site Request Forgery (CSRF)
      Missing or static state parameter
      Login CSRF
    Token Interception
      Local storage XSS exfiltration
      Custom URI scheme hijacking
    Mix-Up Attacks
      Multi-IdP confusion
    Token Replay
      Stolen bearer token used anywhere
```

### 7.1 Cross-Site Request Forgery (CSRF) & State Parameter

#### Attack Mechanics (Login CSRF):

1. Attacker starts an OAuth flow on `legit-store.com` with their own account.
2. When the Authorization Server redirects to `legit-store.com/callback?code=ATTACKER_CODE`, the attacker intercepts and cancels the request before the browser follows the redirect.
3. The attacker tricks the victim into clicking a link that triggers that exact callback: `https://legit-store.com/callback?code=ATTACKER_CODE`.
4. The victim's browser sends the request. The client exchanges `ATTACKER_CODE` for tokens, binding the victim's session to the **attacker's account**.
5. When the victim enters credit card details or creates sensitive data, it is saved under the attacker's account.

#### Defense: Cryptographic State Binding

```mermaid
flowchart TD
    ClientGen["Client generates random state = CSRF_TOKEN"]
    StoreCookie["Store CSRF_TOKEN in HttpOnly SameSite=Lax Cookie"]
    SendAS["Send state=CSRF_TOKEN in /authorize request"]
    ASRet["AS returns state in redirect callback"]
    VerifyState{"Does callback state<br/>match cookie CSRF_TOKEN?"}

    ClientGen --> StoreCookie --> SendAS --> ASRet --> VerifyState
    VerifyState -- Match --> Proceed["Process Token Exchange"]
    VerifyState -- Mismatch --> Reject["Abort & Alert: CSRF Attack Detected"]
```

---

### 7.2 Open Redirectors and Exact Redirect URI Matching

If an Authorization Server validates `redirect_uri` using **prefix matching**, **regexes**, or **subdomain wildcards** (e.g., `https://*.example.com/*` or `https://app.example.com/oauth/`), an attacker can chain an **open redirector** or **path traversal** vulnerability on the trusted domain to exfiltrate authorization codes or tokens.

#### Attack Mechanics (Wildcard / Prefix Bypass + Open Redirector):

```mermaid
sequenceDiagram
    autonumber
    actor Victim as Victim (User-Agent)
    participant Attacker as Attacker (evil.com)
    participant AS as Authorization Server
    participant VulnEndpoint as Trusted Domain Open Redirect<br/>(blog.example.com/out)

    Attacker->>Victim: Sends crafted /authorize link<br/>(redirect_uri=https://blog.example.com/out?next=https://evil.com)
    Victim->>AS: GET /authorize?redirect_uri=https://blog.example.com/out?next=https://evil.com
    Note over AS: Loose validation matches pattern<br/>https://*.example.com/* -> Accepted!
    Victim->>AS: Authenticates & consents (or auto-approved via SSO)
    AS-->>Victim: 302 Redirect to<br/>https://blog.example.com/out?next=https://evil.com&code=AUTH_CODE
    Victim->>VulnEndpoint: GET /out?next=https://evil.com&code=AUTH_CODE
    VulnEndpoint-->>Victim: Redirects to https://evil.com<br/>(forwarding query params, preserving #fragment, or leaking via Referer)
    Victim->>Attacker: Requests https://evil.com with leaked AUTH_CODE
    Attacker->>AS: POST /token (exchanges AUTH_CODE if PKCE is absent)
```

#### Common Bypass & Leakage Vectors:

1. **Wildcard Subdomain Hijacking**: A registered pattern like `https://*.example.com/callback` allows targeting any subdomain (e.g., `blog.example.com` or an unmaintained microsite) that exposes an open redirect.
2. **Prefix & Path Traversal**: A registered prefix like `https://app.example.com/oauth/` can be bypassed via `https://app.example.com/oauth/../../redirect?url=https://evil.com` if the Authorization Server checks `startsWith()` without normalizing path segments.
3. **How the Credential Leaks Across the Redirect**:
   - **Query-forwarding open redirect**: The intermediate endpoint forwards incoming query parameters (`code`, `state`) onto the target URL.
   - **Client-side / JS redirect (`Referer` leak)**: A page redirecting via `window.location` or `<meta http-equiv="refresh">` can expose the full URL (including `?code=...`) in the `Referer` header to `evil.com` unless restricted by `Referrer-Policy`.
   - **URL Fragment Preservation**: In legacy Implicit flows (`#access_token=...`) or `response_mode=fragment`, browsers retain the `#fragment` across HTTP `302` redirects directly to `evil.com`.

#### Defense: Exact Byte-for-Byte String Matching (OAuth 2.1 / RFC 9700)

```mermaid
flowchart LR
    Req["Incoming redirect_uri<br/>from /authorize"] --> Check{"Exact string match<br/>against registered URI?"}
    Check -- "Yes (Exact match)" --> Allow["Proceed with Authorization"]
    Check -- "No (Extra path, query, traversal, or subdomain)" --> Reject["Reject Immediately (400 Bad Request)<br/>Do NOT redirect to invalid URI"]
```

> [!CAUTION]
> **OAuth 2.1 Mitigation**: Authorization Servers **must** require exact string comparison (`RFC 3986 §6.2.1`) for all registered redirect URIs—subdomain wildcards, regexes, and unnormalized path prefix matching are forbidden. When `redirect_uri` is invalid or unregistered, the Authorization Server must display an error directly rather than redirecting. Pairing exact matching with **PKCE** provides defense-in-depth by ensuring a leaked `code` cannot be redeemed without `code_verifier`.

---

### 7.3 Securing Bearer Tokens: DPoP (RFC 9449)

Standard OAuth access tokens are **Bearer Tokens**: whoever holds the token can use it, like physical cash. If an attacker steals an access token via XSS, local storage, or network sniffing, the Resource Server cannot distinguish between the legitimate client and the thief.

**DPoP (Demonstrating Proof-of-Possession, [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449))** transforms access tokens into **Sender-Constrained Tokens** cryptographically bound to an asymmetric key pair held by the client. Every protected request must include both the bound access token and a fresh **DPoP Proof** signed by the matching private key.

```mermaid
sequenceDiagram
    autonumber
    actor User as Resource Owner
    participant Client as Client (SPA / Mobile)
    participant AS as Authorization Server
    participant RS as Resource Server

    Note over Client: 1. Key Setup (once per device/session)<br/>Generates non-extractable key pair (e.g., ES256)

    User->>Client: Click "Sign in"
    Client->>AS: GET /authorize (+ PKCE code_challenge, optional dpop_jkt)
    AS->>User: Authenticate & Consent
    AS-->>Client: 302 Redirect (?code=AUTH_CODE)

    Note over Client: 2. Token Exchange<br/>Signs DPoP Proof with private key<br/>(typ="dpop+jwt", jwk=PUB_KEY, htm="POST", htu="/token", jti, iat)
    Client->>AS: POST /token (code, code_verifier)<br/>Header: DPoP: <DPoP_PROOF_JWT>
    opt Server requires nonce freshness (RFC 9449 §8)
        AS-->>Client: 400 (error="use_dpop_nonce", Header: DPoP-Nonce: <NONCE>)
        Client->>AS: Retry POST /token with DPoP Proof containing nonce=<NONCE>
    end
    AS->>AS: Verify PKCE, DPoP signature, and compute jkt = Base64URL(SHA256(jwk))
    Note over AS: Binds access_token (cnf.jkt) and<br/>public client's refresh_token to jkt
    AS-->>Client: 200 OK (access_token, refresh_token, token_type: "DPoP")

    Note over Client: 3. Protected API Call<br/>Signs fresh DPoP Proof (htm="GET", htu="/api/orders", jti, ath=SHA256(access_token))
    Client->>RS: GET /api/orders<br/>Header: Authorization: DPoP <ACCESS_TOKEN><br/>Header: DPoP: <DPoP_PROOF_JWT>
    RS->>RS: 1. Verify DPoP signature with proof.header.jwk<br/>2. Check Base64URL(SHA256(jwk)) == access_token.cnf.jkt<br/>3. Verify htm, htu, iat, jti (replay), and ath (token hash)
    RS-->>Client: 200 OK (Protected Resource)

    Note over Client,AS: 4. Token Refresh (same private key)<br/>POST /token (grant_type=refresh_token) must include a new DPoP proof signed by the same key
```

#### 1. What is a DPoP Proof? (`DPoP` Header JWT)

A **DPoP Proof** is a short-lived, single-use JWT created by the client for **one specific HTTP request** (`RFC 9449 §4.2`). Unlike an access token (issued by the AS), the DPoP proof is **self-signed by the client** and sent in the `DPoP` HTTP header:

```json
// JWT Header
{
  "typ": "dpop+jwt",   // Prevents cross-protocol confusion with access/ID tokens
  "alg": "ES256",      // Asymmetric algorithm only (HS256 / "none" forbidden)
  "jwk": {             // Client's PUBLIC key embedded inline (never the private key)
    "kty": "EC",
    "crv": "P-256",
    "x": "l8tFrhx-34tV3hRICRDY9zCkDlpBhF42UQUfWVAWBFs",
    "y": "9VE4jf_Ok_o64zbTTlcuNJajHmt6v9TDVrU0CdvGRDA"
  }
}

// JWT Payload
{
  "jti": "e1c9d3f4-8b2a-4c6e-9f1a-2d3b4c5e6f7a", // Unique ID to block replay attacks
  "htm": "GET",                                   // Target HTTP method
  "htu": "https://api.example.com/orders",        // Target URI (without query or fragment)
  "iat": 1795245100,                              // Fresh timestamp (tight TTL window)
  "ath": "fUHyO2r2Z3DZ53EsNrW..._bK3w"            // Base64URL(SHA-256(access_token)) — binds proof to token
}
```

**How the Signature is Computed (Standard JWS with Client Private Key):**

Yes — the signature is always computed using the **client's asymmetric private key** (matching the public key embedded in `header.jwk`), following standard JWS Compact Serialization ([RFC 7515](https://datatracker.ietf.org/doc/html/rfc7515)):

1. **Build the signing input** by Base64URL-encoding the UTF-8 JSON of the header and payload:
   ```text
   signing_input = Base64URL(header_json) + "." + Base64URL(payload_json)
   ```
   _(Because `jwk` is inside `header_json`, the embedded public key itself is integrity-protected by the signature.)_
2. **Sign with the private key** using the asymmetric algorithm declared in `alg` (e.g., `ES256` = ECDSA P-256 + SHA-256):
   ```text
   signature = Sign(client_private_key, ASCII(signing_input))
   ```
   In a browser, `crypto.subtle.sign(...)` computes this inside the Web Crypto subsystem using the non-extractable `CryptoKey` handle without ever exposing the raw private key bytes to JavaScript.
3. **Assemble the `DPoP` header value**:
   ```text
   DPoP = signing_input + "." + Base64URL(signature)
   ```
4. **Server verification**: The AS or Resource Server extracts the **public key** from `header.jwk`, verifies `signature` over `signing_input` with that public key, and confirms `jwk`'s thumbprint matches `cnf.jkt`. Because only the matching private key can produce a valid signature for `header.jwk`, passing verification proves possession of the private key.

> [!NOTE]
> **`ath` (Access Token Hash)** is required whenever the DPoP proof accompanies an access token to a Resource Server, preventing an attacker from pairing a valid DPoP proof with a different token. Some servers also issue a **`DPoP-Nonce`** header that the client must echo in the proof's `nonce` claim to enforce server-controlled freshness.

#### 2. What is a JWK Thumbprint (`jkt`) and `cnf.jkt` Binding?

A **JWK Thumbprint (`jkt`)**, standardized in [RFC 7638](https://datatracker.ietf.org/doc/html/rfc7638), is a canonical, deterministic **SHA-256 fingerprint** of a public key's required JWK members (ignoring optional metadata like `kid`, `use`, or `alg`):

```mermaid
flowchart LR
    JWK["Public JWK in Proof Header<br/>{crv, kty, x, y}"] --> Canonical["Canonical JSON (RFC 7638)<br/>Lexicographically sorted required fields"]
    Canonical --> Hash["SHA-256 + Base64URL"]
    Hash --> JKT["jkt Thumbprint<br/>'0ZcOCORZNYy-DWpqq30j...'"]
    JKT --> Token["Embedded in Access Token<br/>cnf: { jkt: '0ZcOCORZNYy...' }"]
    Token --> Verify["RS compares SHA256(proof.jwk) == token.cnf.jkt"]
```

- Why not embed the entire public key in the access token? Using `jkt` keeps access tokens compact while still uniquely identifying the exact public key via the `cnf` (Confirmation, [RFC 7800](https://datatracker.ietf.org/doc/html/rfc7800)) claim.
- For **opaque access tokens**, the AS stores `jkt` alongside the token record and returns `cnf.jkt` in its `/introspect` response (Section 4.6) so the Resource Server can still verify the binding.

#### 3. How Clients Store the Private Key Securely

DPoP's guarantee depends on keeping the private key **non-extractable** so stolen tokens cannot be replayed from another device:

| Client Environment       | Recommended Key Storage Mechanism                         | Security Properties & Caveats                                                                                                                                                                                                                                                                                                                                                       |
| :----------------------- | :-------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SPA (Web Browser)**    | **Web Crypto API** (`extractable: false`) + **IndexedDB** | `crypto.subtle.generateKey(..., false, ["sign"])` creates a `CryptoKey` handle stored in IndexedDB (`localStorage` cannot store `CryptoKey` objects). JS can sign proofs without ever reading raw key bytes—blocking off-device key exfiltration. _(Caveat: active XSS in the same tab can still call `sign()` while the session is open; use **BFF** in Section 8 when possible.)_ |
| **iOS Native App**       | **Secure Enclave** + **Keychain**                         | Private key is generated inside hardware (`kSecAttrTokenIDSecureEnclave`); raw bytes never enter app RAM.                                                                                                                                                                                                                                                                           |
| **Android Native App**   | **Android Keystore** (**TEE** / **StrongBox**)            | Signing executes inside the hardware Trusted Execution Environment or StrongBox HSM (`isStrongBoxBacked(true)`).                                                                                                                                                                                                                                                                    |
| **Confidential Backend** | **Cloud KMS / HSM** or **TPM-backed Keystore**            | Asymmetric signing via KMS/HSM APIs or OS hardware-sealed vaults ensures key material never sits in plaintext config or disk files.                                                                                                                                                                                                                                                 |

If an attacker intercepts a DPoP-bound access token, it is useless off-device because they cannot forge fresh `DPoP` proofs without access to the client's non-extractable private key.

---

## 8. Modern Frontend Architecture: The Backend-For-Frontend (BFF) Pattern

Storing access and refresh tokens directly in browser storage (`localStorage` or `sessionStorage`) exposes them to theft via Cross-Site Scripting (XSS).

To eliminate this vulnerability in Single-Page Applications (SPAs), industry best practice has shifted to the **Backend-For-Frontend (BFF) Pattern**:

```mermaid
flowchart LR
    Browser["Single Page Application<br/>(React / Vue / Svelte)<br/>Runs in Browser"]
    BFF["Backend-For-Frontend (BFF)<br/>(Next.js API Routes, Envoy, Go/Node Proxy)<br/><b>Confidential Client</b>"]
    AS["Authorization Server"]
    RS["Resource Server APIs"]

    Browser <-->|"Encrypted, HttpOnly, SameSite=Strict Cookie"| BFF
    BFF <-->|"OAuth 2.0 Code Flow + PKCE + Client Secret"| AS
    BFF <-->|"Bearer Token (Authorization: Bearer ...)"| RS
```

### Why the BFF Pattern is Superior

1. **SPA Never Sees OAuth Tokens**: The browser only holds a secure, encrypted `HttpOnly`, `SameSite=Strict`, `Secure` session cookie. JavaScript running in the DOM cannot read this cookie, neutralizing token exfiltration via XSS.
2. **Confidential Client Security**: The BFF runs on a server and can securely authenticate to the Authorization Server using a `client_secret` or private key.
3. **Automatic Token Refresh**: The BFF automatically transparently refreshes expired access tokens in the background before proxying requests to downstream Resource Servers.

---

## 9. Summary: OAuth 2.0 vs. OAuth 2.1 Changes

OAuth 2.1 consolidates and updates the core specifications ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749), [RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750), [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636), [RFC 8252](https://datatracker.ietf.org/doc/html/rfc8252)).

```mermaid
flowchart TD
    subgraph OAuth21Standards ["OAuth 2.1 Specification Overhaul"]
        PKCE["PKCE is Mandatory<br/>for all Authorization Code flows"]
        NoImplicit["Implicit Grant Removed<br/>(No response_type=token)"]
        NoROPC["ROPC Grant Removed<br/>(No grant_type=password)"]
        ExactRedirect["Exact String Match Required<br/>for all redirect_uri checks"]
        RefreshProtect["Refresh Tokens for Public Clients<br/>must use sender-constraining or rotation"]
        BearerURL["Bearer Tokens in Query Params<br/>Completely Forbidden"]
    end
```

| Security Dimension                   | OAuth 2.0 Baseline                                                               | OAuth 2.1 Standard                                                                                                                                                                           |
| :----------------------------------- | :------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **PKCE**                             | Optional extension (RFC 7636).                                                   | **Mandatory** for all clients using authorization codes.                                                                                                                                     |
| **Implicit Grant**                   | Supported (`response_type=token`, returned `#access_token=...` in URI fragment). | **Removed completely**.                                                                                                                                                                      |
| **Resource Owner Password (ROPC)**   | Supported for legacy apps.                                                       | **Removed completely**.                                                                                                                                                                      |
| **Redirect URI Matching**            | Allowed prefix / wildcard matching.                                              | **Exact string match** required.                                                                                                                                                             |
| **Refresh Tokens (Public Clients)**  | Permitted without restrictions.                                                  | Must be **sender-constrained** ([DPoP](#73-securing-bearer-tokens-dpop-rfc-9449)/mTLS) or use **Refresh Token Rotation (RTR)** ([Section 4.5](#45-refresh-token-rotation--reuse-detection)). |
| **Bearer Token in URI Query String** | Allowed in RFC 6750 §2.3 (`GET /api?access_token=...`), though discouraged.      | **Explicitly forbidden** (must send via `Authorization` header to prevent URL log & `Referer` leakage).                                                                                      |

---

## 10. Key Endpoints Reference

A standard OAuth 2.0 / OIDC identity provider exposes the following well-defined endpoints:

| Endpoint                            | Method         | Purpose                                                                                                                       | Key Parameters                                                                                            |
| :---------------------------------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------- |
| `/.well-known/openid-configuration` | `GET`          | Discovery document returning IdP endpoint URLs and supported features.                                                        | None                                                                                                      |
| `/authorize`                        | `GET`          | Front-channel authorization & user consent.                                                                                   | `response_type`, `client_id`, `redirect_uri`, `scope`, `state`, `code_challenge`, `code_challenge_method` |
| `/token`                            | `POST`         | Back-channel token issuance and refreshing.                                                                                   | `grant_type`, `code`, `redirect_uri`, `client_id`, `client_secret`, `code_verifier`, `refresh_token`      |
| `/userinfo`                         | `GET` / `POST` | OIDC profile endpoint returning claims about the authenticated user.                                                          | `Authorization: Bearer <access_token>`                                                                    |
| `/revoke`                           | `POST`         | Token revocation endpoint ([RFC 7009](https://datatracker.ietf.org/doc/html/rfc7009)) to invalidate access or refresh tokens. | `token`, `token_type_hint`                                                                                |
| `/introspect`                       | `POST`         | Token introspection endpoint ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662)) for opaque tokens.                   | `token`, `token_type_hint`                                                                                |
| `/.well-known/jwks.json`            | `GET`          | JSON Web Key Set (JWKS) containing public keys for validating JWT signatures.                                                 | None                                                                                                      |

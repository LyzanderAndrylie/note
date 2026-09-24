# OAuth 2.0, OAuth 2.1, and Modern Authorization Architectures

A technical guide and engineering reference on the OAuth authorization framework, grant flows, cryptographic extensions (PKCE, DPoP), OpenID Connect (OIDC) identity federation, security threat models, and architectural patterns.

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
flowchart TD
    subgraph OAuthEcosystem ["OAuth 2.0 Delegation Model"]
        RO["Resource Owner<br/>(End User)"]
        Client["Client Application<br/>(SPA, Mobile App, Backend Service)"]
        AS["Authorization Server<br/>(IdP / OAuth AS)"]
        RS["Resource Server<br/>(Protected API)"]
    end

    RO -->|"1. Grants Consent"| AS
    Client -->|"2. Requests Access on behalf of User"| AS
    AS -->|"3. Issues Access Token"| Client
    Client -->|"4. Presents Access Token (Bearer)"| RS
    RS -->|"5. Returns Protected Resource"| Client
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
  - **Opaque (Reference Token)**: A random string serving as a database lookup key; requires token introspection (`RFC 7662`) by the Resource Server.
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

- **No Resource Owner Interaction**: The client acts on its own behalf.
- **No Refresh Tokens**: Since the client can authenticate unattended using its static credentials, issuing refresh tokens creates unnecessary state. When the access token expires, the client simply calls `/token` again.

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

If an Authorization Server permits loose matching or wildcards (e.g., `https://*.example.com/oauth/callback` or regex matching):

1. An attacker discovers an open redirect flaw on any subdomain: `https://blog.example.com/redirect?url=https://evil.com`.
2. The attacker crafts an authorization request with `redirect_uri=https://blog.example.com/redirect?url=https://evil.com`.
3. The Authorization Server validates the URL against the wildcard pattern and redirects the user with the authorization code.
4. The intermediate vulnerable page forwards the request to `evil.com`, leaking the `code` in the query string to the attacker.

> [!CAUTION]
> **OAuth 2.1 Mitigation**: Authorization Servers **must** require exact string comparison for all registered redirect URIs. Subdomain wildcards and path pattern matching are forbidden.

---

### 7.3 Securing Bearer Tokens: DPoP (RFC 9449)

Standard OAuth access tokens are **Bearer Tokens**: whoever holds the token can use it, like physical cash. If an attacker steals an access token via XSS or network sniffing, the Resource Server cannot distinguish between the legitimate client and the thief.

**DPoP (Demonstrating Proof-of-Possession, [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449))** transforms access tokens into **Sender-Constrained Tokens** bound to a private cryptographic key held by the client.

```mermaid
sequenceDiagram
    autonumber
    participant Client as Client (SPA / Mobile)
    participant AS as Authorization Server
    participant RS as Resource Server

    Note over Client: Generates asymmetric key pair (e.g. ES256)
    Note over Client: Signs DPoP Proof JWT with private key<br/>(htm="POST", htu="/token", jti=uuid, iat=now)
    Client->>AS: POST /token (Header: DPoP: <DPoP_PROOF_JWT>)
    AS->>AS: Verify DPoP signature & thumbprint (jkt)
    Note over AS: Binds access_token to client's public key thumbprint
    AS-->>Client: 200 OK (access_token, token_type: "DPoP")

    Note over Client: Signs new DPoP Proof for API call<br/>(htm="GET", htu="/api/orders", jti=uuid)
    Client->>RS: GET /api/orders<br/>Header: Authorization: DPoP <ACCESS_TOKEN><br/>Header: DPoP: <DPoP_PROOF_JWT>
    RS->>RS: 1. Validate DPoP signature against embedded public key<br/>2. Match public key thumbprint with token claim (cnf.jkt)<br/>3. Verify HTTP method & URL match
    RS-->>Client: 200 OK (Protected Resource)
```

If an attacker intercepts the DPoP-bound access token, they cannot use it against the Resource Server without possessing the client's non-extractable private key to sign fresh DPoP proofs.

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

| Security Dimension                  | OAuth 2.0 Baseline                     | OAuth 2.1 Standard                                              |
| :---------------------------------- | :------------------------------------- | :-------------------------------------------------------------- |
| **PKCE**                            | Optional extension (RFC 7636).         | **Mandatory** for all clients using authorization codes.        |
| **Implicit Grant**                  | Supported (standard for SPAs in 2012). | **Removed completely**.                                         |
| **Resource Owner Password (ROPC)**  | Supported for legacy apps.             | **Removed completely**.                                         |
| **Redirect URI Matching**           | Allowed prefix / wildcard matching.    | **Exact string match** required.                                |
| **Refresh Tokens (Public Clients)** | Permitted without restrictions.        | Must be **sender-constrained** (DPoP/mTLS) or use **Rotation**. |
| **Token in URI Query String**       | Discouraged, but allowed in RFC 6750.  | **Explicitly forbidden**.                                       |

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

---

## References & Further Reading

- [RFC 6749: The OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749)
- [RFC 6750: The OAuth 2.0 Authorization Framework - Bearer Token Usage](https://datatracker.ietf.org/doc/html/rfc6750)
- [RFC 7636: Proof Key for Code Exchange (PKCE)](https://datatracker.ietf.org/doc/html/rfc7636)
- [RFC 8252: OAuth 2.0 for Native Apps (AppAuth)](https://datatracker.ietf.org/doc/html/rfc8252)
- [RFC 8628: OAuth 2.0 Device Authorization Grant](https://datatracker.ietf.org/doc/html/rfc8628)
- [RFC 9449: Demonstrating Proof-of-Possession (DPoP)](https://datatracker.ietf.org/doc/html/rfc9449)
- [The OAuth 2.1 Authorization Framework (Draft)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1)
- [OpenID Connect Core 1.0 Specification](https://openid.net/specs/openid-connect-core-1_0.html)

# Security Audit Report

This document outlines the security vulnerabilities identified in the codebase during the audit.

## Server-Side Vulnerabilities

### 1. Insecure Direct Object Reference (IDOR) / Privilege Escalation
**File:** `server/internal/middleware/auth_middleware.go`
**Severity:** High
**Description:** The authentication middleware contains a fallback mechanism for determining the organization ID (`org_id`). If the JWT token does not contain the `org_id` claim, the middleware trusts the `X-Organization-Id` header provided by the client without verifying that the user is actually a member of that organization. An attacker with a valid token (without the `org_id` claim) could supply an arbitrary organization ID in the header to access data belonging to other organizations.

### 2. Server-Side Request Forgery (SSRF)
**File:** `server/internal/handlers/woo.go` (`CreateWooStore`)
**Severity:** Medium
**Description:** The `CreateWooStore` handler allows users to specify an arbitrary `site_url`. The server makes an HTTP GET request to this URL to validate credentials. Although it enforces HTTPS, it does not prevent requests to internal IP addresses (e.g., internal services running on HTTPS or localhost if configured). Furthermore, the handler returns the response body for 401/403 errors, which could leak sensitive information from internal services.

### 3. Unrestricted File Upload
**File:** `server/internal/handlers/product_handler.go` (`CreateProduct`)
**Severity:** High
**Description:** The product creation handler accepts file uploads and saves them to the `uploads/` directory. While it generates a unique UUID filename, it blindly trusts and appends the file extension from the original filename (`filepath.Ext(file.Filename)`). An attacker could upload a malicious file (e.g., a `.php` shell or an HTML file with malicious JS) which, if served by a misconfigured web server or accessed directly, could lead to Remote Code Execution (RCE) or Stored Cross-Site Scripting (XSS).

### 4. Denial of Service (DoS) via Unbounded Query
**File:** `server/internal/handlers/organization_handler.go` (`GetOrganization`)
**Severity:** Low
**Description:** The `GetOrganization` handler retrieves organization details and preloads all associated users (`Preload("Users")`). For organizations with a very large number of users, this could lead to excessive memory consumption and database load, potentially causing a Denial of Service.

### 5. Webhook Replay Attack
**File:** `server/internal/handlers/woo_webhook.go`
**Severity:** Medium
**Description:** The WooCommerce webhook receiver verifies the request signature but does not check for a timestamp or nonce. This makes the endpoint vulnerable to replay attacks, where an attacker could intercept a valid webhook request and resend it multiple times to trigger duplicate events (e.g., creating duplicate orders or inventory adjustments).

### 6. Weak Internal Authentication
**File:** `server/internal/middleware/internal_auth.go`
**Severity:** Medium
**Description:** The `RequireServiceToken` middleware relies on a single static `SERVICE_TOKEN` environment variable. If this token is leaked or compromised, all internal API endpoints are exposed. A more robust solution (e.g., mTLS or dynamic tokens) is recommended for internal service-to-service communication.

### 7. CORS Misconfiguration
**File:** `server/cmd/api/main.go`
**Severity:** Low
**Description:** The CORS configuration allows any origin starting with `http://localhost`. While suitable for development, this is overly permissive for production and could allow malicious sites running on localhost (e.g., via port forwarding or other local services) to interact with the API.

## Client-Side Vulnerabilities

### 1. Insecure Communication (Cleartext HTTP)
**File:** `client/lib/services/*.go` (e.g., `auth_service.dart`, `product_service.dart`)
**Severity:** Medium
**Description:** The client application is configured to communicate with the backend via `http://localhost:8080`. Using cleartext HTTP exposes sensitive data, including authentication credentials (email/password) and JWT tokens, to interception by attackers on the same network. Production builds must enforce HTTPS.

## Recommendations

1.  **Auth Middleware:** Remove the fallback to `X-Organization-Id` or implement a database check to verify the user's membership in the claimed organization.
2.  **SSRF Protection:** Implement a whitelist of allowed domains or block requests to private/internal IP ranges in the `testWooConnection` function. Do not return response bodies from upstream services in error messages.
3.  **File Upload:** Validate file content types using magic numbers (e.g., `http.DetectContentType`) and whitelist allowed extensions (e.g., `.jpg`, `.png`). Store files outside the web root or serve them via a content delivery network (CDN).
4.  **Pagination:** Implement pagination for the `GetOrganization` user list retrieval.
5.  **Webhook Security:** Verify the timestamp header (if provided by WooCommerce) or implement idempotency checks using the webhook ID to prevent replay attacks.
6.  **HTTPS:** Ensure the client and server are configured to use HTTPS exclusively in production environments.

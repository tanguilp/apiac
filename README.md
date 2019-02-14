# APIsex
APIsex: API security for elixir

APISex is a standard interface for API security and is composed of:
- `APISex.Authenticator`: an Elixir behaviour for API authentication plugs
- `APISex.Filter`: an Elixir behaviour for API filter plugs
- Convenience functions for working with APISex plugs and for HTTP APIs

The following APISex plugs are available:
- `APISex.Authenticator`:
  - [APISexAuthBasic](https://github.com/tanguilp/apisex_auth_basic): implementatoin of the
  Basic HTTP authentication scheme ([RFC7617](https://tools.ietf.org/html/rfc7617))
  - [APISexAuthBearer](https://github.com/tanguilp/apisex_auth_bearer): implementation of the
  Bearer HTTP authentication scheme ([RFC6750](https://tools.ietf.org/html/rfc6750)) and the
  OAuth 2.0 Token Introspection ([RFC7662](https://tools.ietf.org/html/rfc7662)) token
  verification method
  - [APISexAuthMTLS](https://github.com/tanguilp/apisex_auth_mtls): implementation of the
  OAuth 2.0 Mutual TLS Client Authentication and Certificate Bound Access Tokens
  [draft-ietf-oauth-mtls-12 RFC](https://www.ietf.org/id/draft-ietf-oauth-mtls-12.txt)
- `APISex.Filter`:
  - [APISexFilterIPWhitelist](https://github.com/tanguilp/apisex_filter_ip_whitelist):
  IPv4 and IPv6 address whitelisting
  - [APISexFilterIPBlacklist](https://github.com/tanguilp/apisex_filter_ip_blacklist):
  IPv4 and IPv6 address blacklisting
  - [APISexFilterThrottler](https://github.com/tanguilp/apisex_filter_throttler): throttler that
  can throttle on IP address, client, subject, URI, etc.

## Usage

Just use one or more of these aforementioned APISex plugs, this library will be automatically
imported.

## Chaining plugs

`APISex` interfaces are designed so that you can chain APISex plugs. Example:

`my_app/lib/my_app_web/router.ex`
```elixir
pipeline :api_public do
  plug APISexAuthBasic,
    realm: "Public API",
    callback: &MyApp.get_client_secret/2,
    set_error_response: APISexAuthBasic.set_WWWauthenticate_header/3,
    error_response_verbosity: :debug},
  plug APISexAuthBearer,
    bearer_validator:
      {APISexAuthBearer.Validator.Introspect, [
        issuer: "https://example.com/auth"
        tesla_middleware:[
          {Tesla.Middleware.BasicAuth, [username: "client_id_123", password: "WN2P3Ci+meSLtVipc1EZhbFm2oZyMgWIx/ygQhngFbo"]}
        ]]},
    bearer_extract_methods: [:header, :body],
    required_scopes: ["article:write", "comments:moderate"],
    forward_bearer: true,
    cache: {APISexAuthBearerCacheCachex, []}
  plug APISexFilterThrottler,
    key: &APISexFilterThrottler.Functions.throttle_by_ip_path/1,
    scale: 60_000,
    limit: 50,
    exec_cond: &APISex.machine_to_machine?/1,
    error_response_verbosity: :debug}
end
```

## Terminology

APISex uses the OAuth2 terminology:
- the *client* is the server, the machine, accessing the API
- the *subject* is the pysical user (real life person) on behalf on who the API access is performed. Note even though in most cases the subject has authenticated, but it should not be used as a proof of authentication since:
  - this may have be a long time ago (using OAuth2 `refresh_token`)
  - this may not be true at all:
    - in case the subject is impersonnated
    - when using UMA2 flows
  - OAuth2 is an access control protocol, not a federated authentication protocol

APISex plugs are designed for API accesses. Therefore, **do not use it for end-user authentication** as this may lead to **security vulnerabilities**. For example, the `APISexAuthBasic` authenticator does not handle weak user passwords and using it for browser-based authentication by end-user **will** result in **security flaws**.

## Authenticators

The following table summarizes the information of the APISex authenticators:

| Authenticator    | Machine-to-machine         | Accesses of subjects (real persons)                                       |
|------------------|:--------------------------:|:-------------------------------------------------------------------------:|
| APISexAuthBasic | ✔ | |
| APISexAuthBearer | OAuth2 client credentials flow | OAuth2 authorization code, implicit and password flows<br/>OpenID Connect flows |
| APISexAuthnMTLS  | ✔ | |

Machine-to-machine (also known as server-to-server or s2s) refers to access when only machines are involved, without subject.

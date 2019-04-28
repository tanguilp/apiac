# APIac
APIac: API access control for elixir

APIac is a standard interface for API access control and is composed of:
- `APIac.Authenticator`: an Elixir behaviour for API authentication plugs
- `APIac.Filter`: an Elixir behaviour for API filter plugs
- Convenience functions for working with APIac plugs and for HTTP APIs

The following APIac plugs are available:
- `APIac.Authenticator`:
  - [APIacAuthBasic](https://github.com/tanguilp/apiac_auth_basic): implementatoin of the
  Basic HTTP authentication scheme ([RFC7617](https://tools.ietf.org/html/rfc7617))
  - [APIacAuthBearer](https://github.com/tanguilp/apiac_auth_bearer): implementation of the
  Bearer HTTP authentication scheme ([RFC6750](https://tools.ietf.org/html/rfc6750)) and the
  OAuth 2.0 Token Introspection ([RFC7662](https://tools.ietf.org/html/rfc7662)) token
  verification method
  - [APIacAuthMTLS](https://github.com/tanguilp/apiac_auth_mtls): implementation of the
  OAuth 2.0 Mutual TLS Client Authentication and Certificate Bound Access Tokens
  [draft-ietf-oauth-mtls-12 RFC](https://www.ietf.org/id/draft-ietf-oauth-mtls-12.txt)
- `APIac.Filter`:
  - [APIacFilterIPWhitelist](https://github.com/tanguilp/apiac_filter_ip_whitelist):
  IPv4 and IPv6 address whitelisting
  - [APIacFilterIPBlacklist](https://github.com/tanguilp/apiac_filter_ip_blacklist):
  IPv4 and IPv6 address blacklisting
  - [APIacFilterThrottler](https://github.com/tanguilp/apiac_filter_throttler): throttler that
  can throttle on IP address, client, subject, URI, etc.

## Usage

Just use one or more of these aforementioned APIac plugs, this library will be automatically
imported.

## Chaining plugs

`APIac` interfaces are designed so that you can chain APIac plugs. Example:

`my_app/lib/my_app_web/router.ex`
```elixir
pipeline :api_public do
  plug APIacAuthBasic,
    realm: "Public API",
    callback: &MyApp.get_client_secret/2,
    set_error_response: APIacAuthBasic.set_WWWauthenticate_header/3,
    error_response_verbosity: :debug},
  plug APIacAuthBearer,
    bearer_validator:
      {APIacAuthBearer.Validator.Introspect, [
        issuer: "https://example.com/auth"
        tesla_middleware:[
          {Tesla.Middleware.BasicAuth, [username: "client_id_123", password: "WN2P3Ci+meSLtVipc1EZhbFm2oZyMgWIx/ygQhngFbo"]}
        ]]},
    bearer_extract_methods: [:header, :body],
    required_scopes: ["article:write", "comments:moderate"],
    forward_bearer: true,
    cache: {APIacAuthBearerCacheCachex, []}
  plug APIacFilterThrottler,
    key: &APIacFilterThrottler.Functions.throttle_by_ip_path/1,
    scale: 60_000,
    limit: 50,
    exec_cond: &APIac.machine_to_machine?/1,
    error_response_verbosity: :debug}
end
```

## Terminology

APIac uses the OAuth2 terminology:
- the *client* is the server, the machine, accessing the API
- the *subject* is the pysical user (real life person) on behalf on who the API access is performed. Note even though in most cases the subject has authenticated, but it should not be used as a proof of authentication since:
  - this may have be a long time ago (using OAuth2 `refresh_token`)
  - this may not be true at all:
    - in case the subject is impersonnated
    - when using UMA2 flows
  - OAuth2 is an access control protocol, not a federated authentication protocol

APIac plugs are designed for API accesses. Therefore, **do not use it for end-user authentication** as this may lead to **security vulnerabilities**. For example, the `APIacAuthBasic` authenticator does not handle weak user passwords and using it for browser-based authentication by end-user **will** result in **security flaws**.

## Authenticators

The following table summarizes the information of the APIac authenticators:

| Authenticator    | Machine-to-machine         | Accesses of subjects (real persons)                                       |
|------------------|:--------------------------:|:-------------------------------------------------------------------------:|
| APIacAuthBasic | ✔ | |
| APIacAuthBearer | OAuth2 client credentials flow | OAuth2 authorization code, implicit and password flows<br/>OpenID Connect flows |
| APIacAuthnMTLS  | ✔ | |

Machine-to-machine (also known as server-to-server or s2s) refers to access when only machines are involved, without subject.

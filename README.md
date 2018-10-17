# APIsex
APIsex: API security for elixir (Plug)

APISex is a standard interface for API security and is composed of:
- `APISex.Authenticator`: an Elixir behaviour for API authentication plugs
- `APISex.Filter`: an Elixir behaviour for API filter plugs
- Convenience functions for working with APISex plugs and for HTTP APIs

APISex uses the OAuth2 terminology:
- the *client* is the server, the machine, accessing the API
- the *subject* is the pysical user (real life person) on behalf on who the API access is performed. Note even though in most cases the subject has authenticated, but it should not be used as a proof of authentication since:
  - this may have be a long time ago (using OAuth2 `refresh_token`)
  - this may not be true at all:
    - in case the subject is impersonnated
    - when using UMA2 flows

APISex plugs are designed for API accesses. Therefore, **do not use it for end-user authentication** as this may lead to **security vulnerabilities**. For example, the `APISexAuthBasic` authenticator does not handle weak user passwords and using it for browser-based authentication by end-user **will** result in **security flaws**.

The following table summarizes the information of the APISex authenticators:

| Authenticator    | Machine-to-machine         | Accesses of subjects (real persons)                                       |
|------------------|:--------------------------:|:-------------------------------------------------------------------------:|
| [APISexAuthBasic](https://github.com/tanguilp/apisex_auth_basic)  | ✔                          |                                                                           |
| [APISexAuthBearer](https://github.com/tanguilp/apisex_auth_bearer) | ✔<sup>1</sup> | ✔<sup>2</sup> |
| APISexAuthnmTLS  | ✔                          |                                                                           |

<sup>1</sup> Client credentials grant<br>
<sup>2</sup> All OAuth2 grants except Client Credentials Grant, OpenID Connect flows

Machine-to-machine (also known as server-to-server or s2s) refers to access when only machines are involved, without subject.

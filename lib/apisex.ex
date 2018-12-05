defmodule APISex do
  @moduledoc """
  Convenience functions to work with APISex and API requests
  """

  @type realm :: String.t()
  @type client :: String.t()
  @type subject :: String.t()
  @type metadata :: %{String.t() => String.t()}
  @type http_authn_scheme :: String.t()

  @doc """
  Returns `true` if the connection is authenticated by an APISex plug, `false` otherwise
  """

  def authenticated?(%Plug.Conn{private: %{apisex_authenticator: authenticator}})
      when is_atom(authenticator),
      do: true

  def authenticated?(_), do: false

  @doc """
  Returns `true` if this is a machine-to-machine authentication (i.e. no *subject* involved), `false` otherwise
  """
  @spec machine_to_machine?(Plug.Conn.t()) :: boolean()
  def machine_to_machine?(%Plug.Conn{private: %{apisex_client: client}} = conn)
      when is_binary(client) do
    case conn do
      %Plug.Conn{private: %{apisex_subject: subject}} ->
        is_nil(subject)

      _ ->
        true
    end
  end

  def machine_to_machine?(_), do: false

  @doc """
  Returns `true` if the authentication is on behalf of a real user (the *subject*), `false` otherwise
  """

  @spec subject_authenticated?(Plug.Conn.t()) :: boolean()
  def subject_authenticated?(%Plug.Conn{private: %{apisex_subject: sub}}) when is_binary(sub),
    do: true

  def subject_authenticated?(_), do: false

  @doc """
  Returns the `APISex.Authenticator` that has authenticated the connection, `nil` if none has
  """

  @spec authenticator(Plug.Conn.t()) :: atom() | nil
  def authenticator(%Plug.Conn{private: %{apisex_authenticator: authenticator}}),
    do: authenticator

  def authenticator(_), do: nil

  @doc """
  Returns the name of the client, or `nil` if the connection is unauthenticated
  """

  @spec client(Plug.Conn.t()) :: client | nil
  def client(%Plug.Conn{private: %{apisex_client: client}}), do: client
  def client(_), do: nil

  @doc """
  Returns the name of the subject, or `nil` if it was not set (unauthenticated connection, machine-tomachine authentication...)
  """

  @spec subject(Plug.Conn.t()) :: subject | nil
  def subject(%Plug.Conn{private: %{apisex_subject: subject}}), do: subject
  def subject(_), do: nil

  @doc """
  Returns metadata associated with the authenticated connection, or `nil` if there's none
  """

  @spec metadata(Plug.Conn.t()) :: %{String.t() => String.t()} | nil
  def metadata(%Plug.Conn{private: %{apisex_metadata: metadata}}), do: metadata
  def metadata(_), do: nil

  @doc """
  Sets the HTTP WWW-Authenticate header of a `Plug.Conn` and returns it.

  Note that the parameters are passed as a map whose:
  - keys are rfc7230 tokens
  - values are rfc7230 quoted-strings, but **without the enclosing quotes**: they are mandatory and therefore added automatically

  ## Examples
  ```elixir
  iex> conn(:get, "/ressource") |>
  ...> Plug.Conn.put_status(:unauthorized) |>
  ...> APISex.set_WWWauthenticate_challenge("Basic", %{"realm" => "realm_1"}) |>
  ...> APISex.set_WWWauthenticate_challenge("Bearer", %{"realm" => "realm_1", "error" => "insufficient_scope", "scope" => "group:read group:write"})
  %Plug.Conn{
    adapter: {Plug.Adapters.Test.Conn, :...},
    assigns: %{},
    before_send: [],
    body_params: %Plug.Conn.Unfetched{aspect: :body_params},
    cookies: %Plug.Conn.Unfetched{aspect: :cookies},
    halted: false,
    host: "www.example.com",
    method: "GET",
    owner: #PID<0.202.0>,
    params: %Plug.Conn.Unfetched{aspect: :params},
    path_info: ["ressource"],
    path_params: %{},
    peer: {{127, 0, 0, 1}, 111317},
    port: 80,
    private: %{},
    query_params: %Plug.Conn.Unfetched{aspect: :query_params},
    query_string: "",
    remote_ip: {127, 0, 0, 1},
    req_cookies: %Plug.Conn.Unfetched{aspect: :cookies},
    req_headers: [],
    request_path: "/ressource",
    resp_body: nil,
    resp_cookies: %{},
    resp_headers: [
      {"cache-control", "max-age=0, private, must-revalidate"},
      {"www-authenticate",
       "Basic realm=\"realm_1\", Bearer error=\"insufficient_scope\", realm=\"realm_1\", scope=\"group:read group:write\""}
    ],
    scheme: :http,
    script_name: [],
    secret_key_base: nil,
    state: :unset,
    status: 401
  }

  ```
  """
  @spec set_WWWauthenticate_challenge(Plug.Conn.t(), http_authn_scheme, %{
          String.t() => String.t()
        }) :: Plug.Conn.t()
  def set_WWWauthenticate_challenge(conn, scheme, params) do
    if not rfc7230_token?(scheme), do: raise("Invalid scheme value as per RFC7230")

    header_val =
      scheme <>
        " " <>
        Enum.join(
          Enum.map(
            params,
            fn {k, v} ->
              # params come non-quoted - let's quote it now
              v = "\"#{v}\""

              if not rfc7230_token?(k), do: raise("Invalid auth param value")
              # https://tools.ietf.org/html/rfc7235#section-2.2
              #
              #    For historical reasons, a sender MUST only generate the quoted-string
              #    syntax.  Recipients might have to support both token and
              #    quoted-string syntax for maximum interoperability with existing
              #    clients that have been accepting both notations for a long time.
              if not rfc7230_quotedstring?(v), do: raise("Invalid auth param value")

              k <> "=" <> v
            end
          ),
          ", "
        )

    case Plug.Conn.get_resp_header(conn, "www-authenticate") do
      [] ->
        Plug.Conn.put_resp_header(conn, "www-authenticate", header_val)

      [existing_header_val | _] ->
        Plug.Conn.put_resp_header(
          conn,
          "www-authenticate",
          existing_header_val <> ", " <> header_val
        )
    end
  end

  @doc """
  Returns `true` if the input string is an [rfc7230 quoted-string](https://tools.ietf.org/html/rfc7230#section-3.2.6), `false` otherwise
  """

  @spec rfc7230_quotedstring?(String.t()) :: boolean()
  def rfc7230_quotedstring?(val) do
    Regex.run(
      ~r{^"([\v\s\x21\x23-\x5B\x5D-\x7E\x80-\xFF]|\\\v|\\\s|\\[\x21-\x7E]|\\[\x80-\xFF])*"$},
      val
    ) != nil
  end

  @doc """
  Returns `true` if the input string is an rfc7230 token, `false` otherwise
  """

  @spec rfc7230_token?(String.t()) :: boolean()
  def rfc7230_token?(val) do
    Regex.run(~r{^[!#$%&'*+\-.\^_`|~0-9A-Za-z]+$}, val) != nil
  end

  @doc """
  Returns `true` if the input string is an [rfc7235 token68](https://tools.ietf.org/html/rfc7235#section-2.1), `false` otherwise
  """

  @spec rfc7235_token68?(String.t()) :: boolean()
  def rfc7235_token68?(val) do
    Regex.run(~r{^[0-9A-Za-z\-._~+/]+=*$}, val) != nil
  end

  @doc """
  Returns the following error response verbosity level depending on the environment:
  - dev: `:debug`
  - test: `:normal`
  - prod: `:normal`

  It uses the APISex configuration key `:env` that is by defaults executed to `Mix.env()`
  """

  @spec default_error_response_verbosity(Plug.Conn.t()) :: :debug | :normal | :minimal
  def default_error_response_verbosity(_conn) do
    case Application.get_env(:apisex, :env) do
      :dev ->
        :debug

      :test ->
        :normal

      :prod ->
        :normal
    end
  end

  defmodule AuthFailureResponseData do
    @enforce_keys [:module, :reason]
    defstruct [:module, :reason, :www_authenticate_header, :status_code, :body]

    @type t :: %__MODULE__{
      module: module(),
      reason: atom(),
      www_authenticate_header: {String.t(), map()} | nil,
      status_code: Plug.Conn.status() | nil,
      body: String.t() | nil
    }

    @doc """
    Returns the authentication failure information from the `Plug.Conn.t()`
    """
    @spec get(Plug.Conn.t()) :: [t()] | nil
    def get(conn) do
      conn.private[:apisex_failed_auth_response_data]
    end

    @doc """
    Adds authentication failure information to the `Plug.Conn.t()` object
    """
    @spec put(Plug.Conn.t(), t()) :: Plug.Conn.t()
    def put(
      %Plug.Conn{private: %{apisex_failed_auth_response_data: data}} = conn,
      failure_data) when is_list(data) do
      Plug.Conn.put_private(conn, :apisex_failed_auth_response_data, [failure_data | data])
    end

    def put(conn, failure_data) do
      Plug.Conn.put_private(conn, :apisex_failed_auth_response_data, [failure_data])
    end
  end
end

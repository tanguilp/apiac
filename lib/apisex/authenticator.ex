defmodule APISex.Authenticator do
  @moduledoc """
  Specification for authenticator plug

  An authenticator is in charge of extracting and validating credentials. It can
  also returns an error indicating how to authenticate, giving information such as
  authentication scheme to use, etc.
  """

  @type opts :: any()
  @type credentials :: any()

  @doc """
  Extract the credentials from the `Plug.Conn` object

  Returns `{:ok, Plug.Conn.t, credentials}` if credentials were found. It is required
  to return the `Plug.Conn` object since some things can be fetched in the process
  (e.g. the HTTP body). The format of `credentials` is specific to an `APISex.Authenticator`

  Returns `{:error, Plug.Conn.t, %APISex.Authenticator.Unauthorized{}}` if no
  credentials were found or credential extraction failed (because request is malformed,
  parameters are non-standard, or any other reason). When, and only when credentials
  are not present in the request, the `reason` field of the
  `%APISex.Authenticator.Unauthorized{}` shall be set to the atom `:credentials_not_found`.
  The semantics are the following:
  - if credentials were *not* found, the HTTP `WWW-Authenticate` can be set to advertise the
  calling client of the available authentication scheme
  - if credentials were found but an error happens when extracting it, that is an error
  (since the client tried to authenticate) and the plug pipeline execution should be
  stopped

  The `opts` parameter is the value returned by `Plug.init/1`
  """

  @callback extract_credentials(Plug.Conn.t(), opts) ::
              {:ok, Plug.Conn.t(), credentials}
              | {:error, Plug.Conn.t(), %APISex.Authenticator.Unauthorized{}}

  @doc """
  Validate credentials previously extracted by `APISex.Authenticator.extract_credentials/2`

  Returns `{:ok, Plug.Conn.t` if credentials are valid. It is required
  to return the `Plug.Conn` object since some things can be fetched in the process
  (e.g. the HTTP body).

  Returns `{:error, Plug.Conn.t, %APISex.Authenticator.Unauthorized{}}` if
  credentials are invalid

  The `opts` parameter is the value returned by `Plug.init/1`
  """

  @callback validate_credentials(Plug.Conn.t(), credentials, opts) ::
              {:ok, Plug.Conn.t()} | {:error, Plug.Conn.t(), %APISex.Authenticator.Unauthorized{}}

  @doc """
  Sets the HTTP error response and halts the plug

  Typically, the error is returned as:
  - An error status code (e.g. '401 Unauthorized')
  - `WWW-Authenticate` standard HTTP header

  Specifically, it may set the headers, HTTP status code and HTTP body, depending on:
  - The `#{__MODULE__}`
  - The `opts[:error_response_verbosity]` function
  Specifics are to be documented in implementation plugs

  The `opts` parameter is the value returned by `Plug.init/1`
  """

  @callback send_error_response(Plug.Conn.t(), %APISex.Authenticator.Unauthorized{}, opts) ::
              Plug.Conn.t()

  defmodule Unauthorized do
    defexception [:authenticator, :reason]

    def exception(authenticator, reason) do
      %__MODULE__{authenticator: authenticator, reason: reason}
    end

    def message(%__MODULE__{authenticator: authenticator, reason: reason}) do
      "#{authenticator}: #{reason}"
    end
  end
end

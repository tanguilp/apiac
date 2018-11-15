defmodule APISex.Authenticator do
  @moduledoc """
  Specification for authenticator plug

  An authenticator is in charge of extracting and validating credentials. It can
  also returns an error indicating how to authenticate, giving information such as
  authentication scheme to use, etc.
  """

  @type opts :: Keyword.t()
  @type credentials :: any()

  @doc """
  Extract the credentials from the `Plug.Conn` object

  Returns `{:ok, Plug.Conn.t, credentials}` if credentials were found. It is required
  to return the `Plug.Conn` object since some things can be fetched in the process
  (e.g. the HTTP body). The format of `credentials` is specific to an `APISex.Authenticator`

  Returns `{:error, Plug.Conn.t, %APISex.Authenticator.Unauthorized{}}` if no
  credentials were found

  The `opts` parameter is the value returned by `Plug.init/1`
  """

  @callback extract_credentials(Plug.Conn.t(), opts) ::
              {:ok, Plug.Conn.t(), credentials}
              | {:error, Plug.Conn.t(), %APISex.Authenticator.Unauthorized{}}

  @doc """
  Validate credentials rpreviously extracted by `APISex.Authenticator.extract_credentials/2`

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
  Sets the HTTP error response when authentication failed. Typically, the error is returned as:
  - An error status code (e.g. '401 Unauthorized')
  - `WWW-Authenticate` standard HTTP header

  However, some authentication schemes can set the error in other headers, in the HTTP body, etc.

  The `opts` parameter is the value returned by `Plug.init/1`
  """

  @callback set_error_response(Plug.Conn.t(), %APISex.Authenticator.Unauthorized{}, opts) ::
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

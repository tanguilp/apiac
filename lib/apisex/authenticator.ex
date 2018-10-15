defmodule APISex.Authenticator do
  @moduledoc """
  TODO
  """

  @type opts :: Keyword.t
  @type credentials :: any()

  @callback extract_credentials(Plug.Conn.t, opts) ::
    {:ok, Plug.Conn.t, credentials} | {:error, Plug.Conn.t, %APISex.Authenticator.Unauthorized{}}
  
  @callback validate_credentials(Plug.Conn.t, credentials, opts) ::
    {:ok, Plug.Conn.t} | {:error, Plug.Conn.t, %APISex.Authenticator.Unauthorized{}}

  @callback set_error_response(Plug.Conn.t, %APISex.Authenticator.Unauthorized{}, opts) :: Plug.Conn.t

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

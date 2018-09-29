defmodule APISex.Authenticator do
  @moduledoc """
  TODO
  """

  @type t :: atom()

  @type creds :: any()

  @callback extract_credentials(Plug.Conn.t) :: {:ok, {Plug.Conn.t, creds}} | {:error, {Plug.Conn.t, any()}}
  
  @callback validate_credentials(Plug.Conn.t, creds) :: {:ok, Plug.Conn.t} | {:error, Plug.Conn.t}

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

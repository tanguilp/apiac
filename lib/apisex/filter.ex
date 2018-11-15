defmodule APISex.Filter do
  @moduledoc """
  Specification for filter plug

  A filter is a plug that allows or blocks a connection based in the connection
  information.
  """

  @type opts :: any()

  @doc """
  Either allows or blocks the connection

  Returns `{:ok, Plug.Conn.t()}` if the connection is allowed. Returns
  `{:error, Plug.Conn.t(), %APISex.Filter.Forbidden{}}` otherwise.

  The `opts` parameter is the value returned by `Plug.init/1`
  """
  @callback filter(Plug.Conn.t(), opts) ::
              {:ok, Plug.Conn.t()} | {:error, Plug.Conn.t(), %APISex.Filter.Forbidden{}}

  @doc """
  Sets the HTTP error response and halts the plug

  Specifically, it may set the headers, HTTP status code and HTTP body, depending on:
  - The `#{__MODULE__}`
  - The `opts[:error_response_verbosity]` function
  Specifics are to be documented in implementation plugs
  """
  @callback send_error_response(Plug.Conn.t(), %APISex.Filter.Forbidden{}, opts) :: Plug.Conn.t()

  defmodule Forbidden do
    defexception [:filter, :reason, error_data: nil]

    def exception(filter, reason, error_data \\ nil) do
      %__MODULE__{filter: filter, reason: reason, error_data: error_data}
    end

    def message(%__MODULE__{filter: filter, reason: reason}) do
      "#{filter}: #{reason}"
    end
  end
end

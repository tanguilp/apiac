defmodule APISex.Filter do
  @moduledoc """
  TODO
  """

  @type opts :: Keyword.t

  @callback filter(Plug.Conn.t, opts) :: {:ok, Plug.Conn.t} | {:error, Plug.Conn.t, %APISex.Filter.Forbidden{}}

  @callback set_error_response(Plug.Conn.t, %APISex.Filter.Forbidden{}, opts) :: Plug.Conn.t

  defmodule Forbidden do
    defexception [:filter, :reason]

    def exception(filter, reason) do
      %__MODULE__{filter: filter, reason: reason}
    end

    def message(%__MODULE__{filter: filter, reason: reason}) do
      "#{filter}: #{reason}"
    end
  end
end

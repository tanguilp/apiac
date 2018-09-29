defmodule APISex.Filter do
  @moduledoc """
  TODO
  """

  @callback filter(Plug.Conn.t) :: {:ok, Plug.Conn.t} | {:error, {Plug.Conn.t}}

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

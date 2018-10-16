defmodule APISex do
  @moduledoc """
  Documentation for APIsex.
  """

  @type realm :: String.t
  @type client :: String.t
  @type client_attributes :: %{String.t => String.t}
  @type subject :: String.t
  @type subject_attributes :: %{String.t => String.t}
  @type http_authn_scheme :: String.t

  def is_authenticated?(%Plug.Conn{private: %{apisex_authenticator: authenticator}}) when is_atom(authenticator), do: true
  def is_authenticated?(_), do: false

  @spec is_machine_to_machine?(Plug.Conn.t) :: boolean()
  def is_machine_to_machine?(%Plug.Conn{private: %{apisex_client: client, apisex_subject: subject}}) when is_binary(client) and is_nil(subject), do: true
  def is_machine_to_machine?(_), do: false

  @spec is_subject_authenticated?(Plug.Conn.t) :: boolean()
  def is_subject_authenticated?(%Plug.Conn{private: %{apisex_subject: sub}}) when is_binary(sub), do: true
  def is_subject_authenticated?(_), do: false

  @spec authenticator(Plug.Conn.t) :: atom() | nil
  def authenticator(%Plug.Conn{private: %{apisex_authenticator: authenticator}}), do: authenticator
  def authenticator(_), do: nil

  @spec authenticator_data(Plug.Conn.t) :: %{} | nil
  def authenticator_data(%Plug.Conn{private: %{apisex_authenticator_metadata: authenticator_metadata}}), do: authenticator_metadata
  def authenticator_data(_), do: nil

  @spec client(Plug.Conn.t) :: client | nil
  def client(%Plug.Conn{private: %{apisex_client: client}}), do: client
  def client(_), do: nil

  @spec client_attributes(Plug.Conn.t) :: %{String.t => String.t} | nil
  def client_attributes(%Plug.Conn{private: %{apisex_client_attributes: client_attributes}}), do: client_attributes
  def client_attributes(_), do: nil

  @spec subject(Plug.Conn.t) :: subject | nil
  def subject(%Plug.Conn{private: %{apisex_subject: subject}}), do: subject
  def subject(_), do: nil

  @spec subject_attributes(Plug.Conn.t) :: %{String.t => String.t} | nil
  def subject_attributes(%Plug.Conn{private: %{apisex_subject_attributes: subject_attributes}}), do: subject_attributes
  def subject_attributes(_), do: nil

  @spec set_WWWauthenticate_challenge(Plug.Conn.t, http_authn_scheme, %{String.t => String.t}) :: Plug.Conn.t
  def set_WWWauthenticate_challenge(conn, scheme, opts) do
    if not is_rfc7230_token?(scheme), do: raise "Invalid scheme value as per RFC7230"

    header_val = scheme <> " " <> Enum.join(
      Enum.map(
        opts,
        fn {k, v} ->
          if not is_rfc7230_token?(k), do: raise "Invalid auth param value"
          # https://tools.ietf.org/html/rfc7235#section-2.2
          #
          #    For historical reasons, a sender MUST only generate the quoted-string
          #    syntax.  Recipients might have to support both token and
          #    quoted-string syntax for maximum interoperability with existing
          #    clients that have been accepting both notations for a long time.
          if not is_rfc7230_quotedstring?(v), do: raise "Invalid auth param value"

          k <> "=" <> v
        end
      ),
      ","
    )

    case Plug.Conn.get_resp_header(conn, "www-authenticate") do
      [] ->
        Plug.Conn.put_resp_header(conn, "www-authenticate", header_val)

      [existing_header_val|_] ->
        Plug.Conn.put_resp_header(conn, "www-authenticate", existing_header_val <> ", " <> header_val)
    end
  end

  # see https://tools.ietf.org/html/rfc7230#section-3.2.6
  @spec is_rfc7230_quotedstring?(String.t) :: boolean()
  def is_rfc7230_quotedstring?(val) do
    Regex.run(~r{^"([\v\s\x21\x23-\x5B\x5D-\x7E\x80-\xFF]|\\\v|\\\s|\\[\x21-\x7E]|\\[\x80-\xFF])*"$}, val) != nil
  end

  @spec is_rfc7230_token?(String.t) :: boolean()
  def is_rfc7230_token?(val) do
    Regex.run(~r{^[!#$%&'*+\-.\^_`|~0-9A-Za-z]+$}, val) != nil
  end
end

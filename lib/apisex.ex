defmodule APISex do
  @moduledoc """
  Documentation for APIsex.
  """

  @type client :: String.t
  @type client_attributes :: %{String.t => String.t}
  @type subject :: String.t
  @type subject_attributes :: %{String.t => String.t}

  def is_authenticated?(%Plug.Conn{private: %{APISex_authenticator: authenticator}}) when is_atom(authenticator), do: true
  def is_authenticated?(_), do: false

  @spec is_machine_to_machine?(Plug.Conn.t) :: boolean()
  def is_machine_to_machine?(%Plug.Conn{private: %{APISex_client: client, APISex_subject: subject}}) when is_binary(client) and is_nil(subject), do: true
  def is_machine_to_machine?(_), do: false

  @spec is_subject_authenticated?(Plug.Conn.t) :: boolean()
  def is_subject_authenticated?(%Plug.Conn{private: %{APISex_subject: sub}}) when is_binary(sub), do: true
  def is_subject_authenticated?(_), do: false

  @spec authenticator(Plug.Conn.t) :: atom() | nil
  def authenticator(%Plug.Conn{private: %{APISex_authenticator: authenticator}}), do: authenticator
  def authenticator(_), do: nil

  @spec authenticator_data(Plug.Conn.t) :: %{} | nil
  def authenticator_data(%Plug.Conn{private: %{APISex_authenticator_metadata: authenticator_metadata}}), do: authenticator_metadata
  def authenticator_data(_), do: nil

  @spec client(Plug.Conn.t) :: client | nil
  def client(%Plug.Conn{private: %{APISex_client: client}}), do: client
  def client(_), do: nil

  @spec client_attributes(Plug.Conn.t) :: %{String.t => String.t} | nil
  def client_attributes(%Plug.Conn{private: %{APISex_client_attributes: client_attributes}}), do: client_attributes
  def client_attributes(_), do: nil

  @spec subject(Plug.Conn.t) :: subject | nil
  def subject(%Plug.Conn{private: %{APISex_subject: subject}}), do: subject
  def subject(_), do: nil

  @spec subject_attributes(Plug.Conn.t) :: %{String.t => String.t} | nil
  def subject_attributes(%Plug.Conn{private: %{APISex_subject_attributes: subject_attributes}}), do: subject_attributes
  def subject_attributes(_), do: nil
end

defmodule Authn do
  @type t :: %__MODULE__{
    auth_scheme: atom(),
    client: String.t,
    client_attributes: map(),
    subject: String.t | nil,
    subject_attributes: map(),
    realm: String.t,
    scopes: [String.t] | nil
  }

  @enforce_keys [:auth_scheme, :realm]
  defstruct auth_scheme: nil,
            client: nil,
            client_attributes: %{},
            subject: nil,
            subject_attributes: %{},
            realm: nil,
            scopes: []
end

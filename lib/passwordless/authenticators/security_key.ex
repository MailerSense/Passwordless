defmodule Passwordless.Authenticators.SecurityKey do
  @moduledoc """
  An security key authenticator.
  """

  use Passwordless.Schema

  alias Database.ChangesetExt
  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "security_key_authenticators" do
    field :enabled, :boolean, default: true
    field :relying_party_id, :string

    embeds_many :expected_origins, ExpectedOrigin, on_replace: :delete do
      field :url, :string
    end

    belongs_to :app, App, type: :binary_id

    timestamps()
  end

  @fields ~w(
    enabled
    relying_party_id
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}) do
    actor_email
    |> cast(attrs, @fields)
    |> cast_embed(:expected_origins,
      with: &expected_origin_changeset/2,
      sort_param: :expected_origins_sort,
      drop_param: :expected_origins_drop,
      required: true
    )
    |> validate_required(@required_fields)
    |> validate_relying_party_id()
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_relying_party_id(changeset) do
    ChangesetExt.validate_domain(changeset, :relying_party_id)
  end

  defp expected_origin_changeset(expected_origin, attrs) do
    expected_origin
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> ChangesetExt.validate_url(:url)
  end
end

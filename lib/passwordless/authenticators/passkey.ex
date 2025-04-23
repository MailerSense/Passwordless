defmodule Passwordless.Authenticators.Passkey do
  @moduledoc """
  An passkey authenticator.
  """

  use Passwordless.Schema, prefix: "passkey"

  alias Database.ChangesetExt
  alias Passwordless.App

  @uplift_intervals ~w(
    every_challenge
    one_day
    one_week
    one_month
    never_again
  )a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "passkey_authenticators" do
    field :enabled, :boolean, default: true
    field :relying_party_id, :string
    field :uplift_prompt_interval, Ecto.Enum, values: @uplift_intervals, default: :every_challenge
    field :require_user_verification, :boolean, default: false

    embeds_many :expected_origins, ExpectedOrigin, on_replace: :delete, primary_key: false do
      @derive Jason.Encoder

      field :url, :string, primary_key: true
    end

    belongs_to :app, App

    timestamps()
  end

  def intervals, do: @uplift_intervals

  @fields ~w(
    enabled
    relying_party_id
    uplift_prompt_interval
    require_user_verification
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, _opts \\ []) do
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

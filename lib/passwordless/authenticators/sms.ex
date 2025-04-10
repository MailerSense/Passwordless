defmodule Passwordless.Authenticators.SMS do
  @moduledoc """
  An SMS authenticator.
  """

  use Passwordless.Schema, prefix: "smsotp"

  alias Passwordless.App

  @languages ~w(en de fr)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "sms_authenticators" do
    field :enabled, :boolean, default: true
    field :expires, :integer, default: 15
    field :language, Ecto.Enum, values: @languages, default: :en, virtual: true

    belongs_to :app, App

    timestamps()
  end

  @fields ~w(
    enabled
    expires
    language
    app_id
  )a
  @required_fields @fields

  def languages, do: @languages

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = actor_email, attrs \\ %{}, opts \\ []) do
    actor_email
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_number(:expires, greater_than: 0, less_than_or_equal_to: 60)
    |> unique_constraint(:app_id)
    |> unsafe_validate_unique(:app_id, Passwordless.Repo)
    |> assoc_constraint(:app)
  end
end

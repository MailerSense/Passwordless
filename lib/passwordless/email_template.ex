defmodule Passwordless.EmailTemplate do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtpl"

  alias Database.ChangesetExt
  alias Passwordless.App
  alias Passwordless.EmailTemplateLocale

  @tags ~w(email_otp magic_link)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :locales,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_templates" do
    field :name, :string
    field :tags, {:array, Ecto.Enum}, values: @tags, default: []

    has_many :locales, EmailTemplateLocale, preload_order: [asc: :inserted_at]

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    name
    tags
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> cast_assoc(:locales)
    |> validate_tags()
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_tags(changeset) do
    ChangesetExt.clean_array(changeset, :tags)
  end
end

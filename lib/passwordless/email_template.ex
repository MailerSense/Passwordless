defmodule Passwordless.EmailTemplate do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtpl"

  alias Passwordless.App
  alias Passwordless.EmailTemplateVersion

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_templates" do
    field :name, :string

    has_many :versions, EmailTemplateVersion

    belongs_to :app, App

    timestamps()
    soft_delete_timestamp()
  end

  @fields ~w(
    name
    app_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> cast_assoc(:versions)
    |> validate_required(@required_fields)
    |> assoc_constraint(:app)
  end

  # Private
end

defmodule Passwordless.EmailTemplateVersion do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema

  alias Passwordless.EmailTemplate

  @languages ~w(en de fr)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_template_versions" do
    field :language, Ecto.Enum, values: @languages, default: :en

    field :subject, :string
    field :preheader, :string

    field :text_body, :string
    field :html_body, :string
    field :json_body, :map
    field :mjml_body, :string

    belongs_to :email_template, EmailTemplate, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def languages, do: @languages

  @fields ~w(
    language
    subject
    preheader
    text_body
    html_body
    json_body
    mjml_body
    email_template_id
  )a

  @required_fields ~w(
    language
    subject
    email_template_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:email_template_id, :language], error_key: :language)
    |> unsafe_validate_unique([:email_template_id, :language], Passwordless.Repo, error_key: :language)
    |> assoc_constraint(:email_template)
  end

  # Private
end

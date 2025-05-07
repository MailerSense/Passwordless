defmodule Passwordless.EmailTemplateLocale do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtplver"

  alias Database.ChangesetExt
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateStyle

  @styles [
    email_otp: ~w(email_otp_clean)a,
    magic_link: ~w(magic_link_clean)a
  ]
  @languages ~w(en de fr)a
  @styles_flat @styles |> Enum.flat_map(fn {_key, values} -> values end) |> Enum.uniq()

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :style,
      :language,
      :subject,
      :preheader,
      :mjml_body,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_template_locales" do
    field :style, Ecto.Enum, values: @styles_flat, default: :email_otp_clean
    field :language, Ecto.Enum, values: @languages, default: :en
    field :current_language, Ecto.Enum, values: @languages, default: :en, virtual: true
    field :subject, :string
    field :preheader, :string
    field :mjml_body, :string

    has_many :styles, EmailTemplateStyle

    belongs_to :email_template, EmailTemplate

    timestamps()
  end

  def styles, do: @styles
  def languages, do: @languages

  def put_current_language(%__MODULE__{} = locale, language) do
    %__MODULE__{locale | current_language: language}
  end

  @fields ~w(
    style
    language
    current_language
    subject
    preheader
    mjml_body
    email_template_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = email_template, attrs \\ %{}, opts \\ []) do
    email_template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_subject()
    |> validate_preheader()
    |> validate_body()
    |> unique_constraint([:email_template_id, :language], error_key: :language)
    |> unsafe_validate_unique([:email_template_id, :language], Passwordless.Repo, error_key: :language)
    |> assoc_constraint(:email_template)
  end

  # Private

  defp validate_subject(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:subject)
    |> ChangesetExt.validate_profanities(:subject)
    |> validate_length(:subject, min: 1, max: 255)
  end

  defp validate_preheader(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:preheader)
    |> ChangesetExt.validate_profanities(:preheader)
    |> validate_length(:preheader, min: 1, max: 255)
  end

  defp validate_body(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:mjml_body)
    |> update_change(:mjml_body, &Passwordless.Formatter.format!(&1, :html))
    |> validate_length(:mjml_body, min: 1, max: 10_000)
  end
end

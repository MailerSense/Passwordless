defmodule Passwordless.EmailTemplateLocale do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtplver"

  alias Database.ChangesetExt
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateStyle
  alias Passwordless.Templating.MJML

  @styles [
    email_otp: ~w(email_otp_clean email_otp_card)a,
    magic_link: ~w(magic_link_clean magic_link_card)a
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
      :html_body,
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
    field :html_body, :string
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
    html_body
    mjml_body
    email_template_id
  )a
  @required_fields @fields -- [:html_body]

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> update_html_body()
    |> validate_subject()
    |> validate_preheader()
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

  defp update_html_body(changeset) do
    case fetch_field(changeset, :mjml_body) do
      {_, mjml_body} when is_binary(mjml_body) ->
        case MJML.convert(mjml_body) do
          {:ok, html_body} ->
            changeset
            |> put_change(:html_body, html_body)
            |> update_change(:html_content, &HtmlSanitizeEx.html5/1)

          {:error, error} ->
            add_error(
              changeset,
              :mjml_body,
              "invalid syntax: %{error}",
              error: error
            )
        end

      _ ->
        changeset
    end
  end
end

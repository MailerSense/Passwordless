defmodule Passwordless.EmailTemplateVersion do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtplver"

  alias Passwordless.EmailTemplate
  alias Passwordless.Templating.MJML

  @styles ~w(clean card)a
  @languages ~w(en de fr)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :language,
      :subject,
      :preheader,
      :text_body,
      :html_body,
      :json_body,
      :mjml_body,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_template_versions" do
    field :language, Ecto.Enum, values: @languages, default: :en
    field :current_style, Ecto.Enum, values: @styles, default: :clean, virtual: true
    field :current_language, Ecto.Enum, values: @languages, default: :en, virtual: true

    field :subject, :string
    field :preheader, :string

    field :text_body, :string
    field :html_body, :string
    field :json_body, :map
    field :mjml_body, :string

    belongs_to :email_template, EmailTemplate

    timestamps()
    soft_delete_timestamp()
  end

  def styles, do: @styles
  def languages, do: @languages

  def put_current_language(%__MODULE__{} = version, language) do
    %__MODULE__{version | current_language: language}
  end

  @fields ~w(
    language
    current_style
    current_language
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
    preheader
    email_template_id
  )a

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> update_html_body()
    |> unique_constraint([:email_template_id, :language], error_key: :language)
    |> unsafe_validate_unique([:email_template_id, :language], Passwordless.Repo, error_key: :language)
    |> assoc_constraint(:email_template)
  end

  # Private

  defp update_html_body(changeset) do
    with {_, mjml_body} when is_binary(mjml_body) <- fetch_field(changeset, :mjml_body),
         {:ok, html_body} <- MJML.convert(mjml_body) do
      put_change(changeset, :html_body, html_body)
    else
      _ -> changeset
    end
  end
end

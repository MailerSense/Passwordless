defmodule Passwordless.EmailTemplateStyle do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtplstyl"

  alias Passwordless.EmailTemplateLocale
  alias Passwordless.Templating.MJML

  @styles [
    email: ~w(email_otp_clean email_otp_card)a,
    magic_link: ~w(magic_link_clean magic_link_card)a
  ]
  @styles_flat @styles |> Enum.flat_map(fn {_key, values} -> values end) |> Enum.uniq()

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :style,
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
  schema "email_template_styles" do
    field :style, Ecto.Enum, values: @styles_flat, default: :email_otp_clean
    field :html_body, :string
    field :mjml_body, :string

    belongs_to :email_template_locale, EmailTemplateLocale

    timestamps()
  end

  def styles, do: @styles

  @fields ~w(
    style
    html_body
    mjml_body
    email_template_locale_id
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
    |> unique_constraint([:email_template_locale_id, :style], error_key: :style)
    |> assoc_constraint(:email_template_locale)
  end

  # Private

  defp update_html_body(changeset) do
    with {_, mjml_body} when is_binary(mjml_body) <- fetch_field(changeset, :mjml_body),
         {:ok, html_body} <- MJML.convert(mjml_body) do
      changeset
      |> put_change(:html_body, html_body)
      |> update_change(:html_content, &HtmlSanitizeEx.html5/1)
    else
      _ -> changeset
    end
  end
end

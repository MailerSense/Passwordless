defmodule Passwordless.EmailTemplateStyle do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema, prefix: "emtplstyl"

  alias Database.ChangesetExt
  alias Passwordless.EmailTemplateLocale

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
    field :mjml_body, :string

    belongs_to :email_template_locale, EmailTemplateLocale

    timestamps()
  end

  def styles, do: @styles

  @fields ~w(
    style
    mjml_body
    email_template_locale_id
  )a
  @required_fields @fields

  @doc """
  A changeset.
  """
  def changeset(%__MODULE__{} = email_template_style, attrs \\ %{}) do
    email_template_style
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_body()
    |> unique_constraint([:email_template_locale_id, :style], error_key: :style)
    |> assoc_constraint(:email_template_locale)
  end

  # Private

  defp validate_body(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:mjml_body)
    |> update_change(:mjml_body, &Passwordless.Formatter.format!(&1, :html))
    |> validate_length(:mjml_body, min: 1, max: 10_000)
  end
end

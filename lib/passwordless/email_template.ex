defmodule Passwordless.EmailTemplate do
  @moduledoc """
  An email template to be dynamically sent.
  """

  use Passwordless.Schema

  alias Passwordless.App
  alias Passwordless.EmailTemplateVersion

  @kinds [
    magic_link: ~w(first_sign_in sign_in)a,
    email_otp: ~w(first_sign_in sign_in)a
  ]
  @kind_flat Enum.flat_map(@kinds, fn {kind, kinds} -> Enum.map(kinds, &:"#{kind}_#{&1}") end)
  @editors ~w(text markdown editorjs mjml)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "email_templates" do
    field :kind, Ecto.Enum, values: @kind_flat
    field :editor, Ecto.Enum, values: @editors, default: :markdown

    has_many :versions, EmailTemplateVersion

    belongs_to :app, App, type: :binary_id

    timestamps()
    soft_delete_timestamp()
  end

  def kinds, do: @kind_flat
  def editors, do: @editors
  def hierarchical_kinds, do: @kinds

  @fields ~w(
    kind
    editor
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
    |> unique_constraint([:app_id, :kind], error_key: :kind)
    |> unsafe_validate_unique([:app_id, :kind], Passwordless.Repo, error_key: :kind)
    |> assoc_constraint(:app)
  end

  # Private
end

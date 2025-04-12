defmodule Passwordless.Media do
  @moduledoc """
  Media are files uploaded to the system to be attached publically or privately to email templates.
  """

  use Passwordless.Schema, prefix: "media"

  import Ecto.Query

  alias Database.ChangesetExt
  alias Passwordless.App

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "media" do
    field :name, :string
    field :mime, :string
    field :size, :integer
    field :public_url, :string

    belongs_to :app, App

    timestamps()
  end

  @doc """
  Get media for an app.
  """
  def get_by_app(%App{} = app) do
    from a in __MODULE__, where: a.app_id == ^app.id
  end

  @fields ~w(name mime size public_url app_id)a

  @doc """
  A media changeset.
  """
  def changeset(%__MODULE__{} = media, attrs \\ %{}) do
    media
    |> cast(attrs, @fields)
    |> validate_name()
    |> validate_size()
    |> put_mime()
    |> validate_mime()
    |> validate_public_url()
    |> assoc_constraint(:app)
  end

  # Private

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_length(:name, min: 1, max: 160)
    |> update_change(:name, &Path.basename/1)
  end

  defp validate_size(changeset) do
    Sizeable.changeset()
    |> validate_required([:size])
    |> validate_number(:size, greater_than: 0, less_than: 10_485)
  end

  defp validate_mime(changeset) do
    validate_required(changeset, [:mime])
  end

  defp validate_public_url(changeset) do
    changeset
    |> validate_required([:public_url])
    |> validate_length(:public_url, max: 255)
    |> validate_format(:public_url, ~r/^https?:\/\/.+/)
  end

  defp put_mime(changeset) do
    case get_field(changeset, :name) do
      name when is_binary(name) ->
        put_change(changeset, :mime, MIME.from_path(name))

      _ ->
        changeset
    end
  end
end

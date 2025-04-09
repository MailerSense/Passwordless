defmodule PasswordlessWeb.Admin.AppLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.App,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.App.changeset/3,
      create_changeset: &Passwordless.App.changeset/3
    ]

  import Ecto.Query

  alias Passwordless.App
  alias PasswordlessWeb.Admin.Filters.SoftDelete, as: SoftDeleteFilter
  alias PasswordlessWeb.Admin.ItemActions.SoftDelete, as: SoftDeleteAction
  alias PasswordlessWeb.Admin.ItemActions.SoftRecover, as: SoftRecoverAction

  @impl Backpex.LiveResource
  def can?(_assigns, :soft_delete, item), do: is_nil(item.deleted_at)

  @impl Backpex.LiveResource
  def can?(_assigns, :soft_recover, item), do: not is_nil(item.deleted_at)

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: true

  @impl Backpex.LiveResource
  def singular_name, do: "App"

  @impl Backpex.LiveResource
  def plural_name, do: "Apps"

  @impl Backpex.LiveResource
  def fields do
    [
      id: %{
        label: "ID",
        module: Backpex.Fields.Text,
        only: [:show]
      },
      name: %{
        module: Backpex.Fields.Text,
        label: "Name",
        searchable: true
      },
      logo: %{
        module: Backpex.Fields.URL,
        label: "Logo",
        searchable: true
      },
      state: %{
        module: Backpex.Fields.Select,
        label: "State",
        options: fn _assigns -> Enum.map(App.states(), &{String.capitalize(Atom.to_string(&1)), &1}) end,
        index_editable: true
      },
      website: %{
        module: Backpex.Fields.URL,
        label: "Website",
        searchable: true
      },
      display_name: %{
        module: Backpex.Fields.Text,
        label: "Display Name",
        searchable: true
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Created At",
        only: [:index, :show],
        format: "%d %b %Y, %H:%M"
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At",
        only: [:index, :show],
        format: "%d %b %Y, %H:%M"
      },
      deleted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Deleted At",
        only: [:show],
        format: "%d %b %Y, %H:%M"
      }
    ]
  end

  @impl Backpex.LiveResource
  def filters do
    [
      deleted: %{
        module: SoftDeleteFilter,
        label: "Deleted?",
        default: ["no"],
        presets: [
          %{
            label: "Both",
            values: fn -> [:yes, :no] end
          },
          %{
            label: "Only deleted",
            values: fn -> [:yes] end
          },
          %{
            label: "Only non deleted",
            values: fn -> [:no] end
          }
        ]
      }
    ]
  end

  @impl Backpex.LiveResource
  def metrics do
    [
      total: %{
        module: Backpex.Metrics.Value,
        label: "Total apps",
        class: "w-full lg:w-1/2",
        select: dynamic([o], count(o.id)),
        format: &Integer.to_string/1
      },
      deleted: %{
        module: Backpex.Metrics.Value,
        label: "Deleted apps",
        class: "w-full lg:w-1/2",
        select: dynamic([o], o.id |> count() |> filter(not is_nil(o.deleted_at))),
        format: &Integer.to_string/1
      }
    ]
  end

  @impl Backpex.LiveResource
  def item_actions(default_actions) do
    default_actions
    |> Keyword.drop([:delete])
    |> Enum.concat(
      soft_delete: %{module: SoftDeleteAction},
      soft_recover: %{module: SoftRecoverAction}
    )
  end
end

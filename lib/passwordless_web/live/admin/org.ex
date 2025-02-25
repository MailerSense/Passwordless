defmodule PasswordlessWeb.Admin.OrgLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.Organizations.Org,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.Organizations.Org.changeset/3,
      create_changeset: &Passwordless.Organizations.Org.changeset/3
    ],
    pubsub: [
      name: Passwordless.PubSub,
      topic: "orgs",
      event_prefix: "org_"
    ],
    fluid?: true

  import Database.QueryExt, only: [array_length: 1]
  import PasswordlessWeb.Components.PageComponents, only: [page_header: 1]

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
  def singular_name, do: "Organization"

  @impl Backpex.LiveResource
  def plural_name, do: "Organizations"

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
      email: %{
        module: Backpex.Fields.Text,
        label: "Email",
        searchable: true
      },
      tags: %{
        module: Backpex.Fields.MultiSelect,
        label: "Tags",
        prompt: "Select organization tags...",
        options: fn _assigns -> [{"Admin", :admin}] end,
        orderable: false
      },
      users: %{
        module: Backpex.Fields.HasMany,
        label: "Users",
        display_field: :full_name,
        select: dynamic([user: u], fragment("concat(?, ' (', ?, ')')", u.name, u.email)),
        options_query: fn query, _assigns ->
          select_merge(query, [user], %{full_name: fragment("concat(?, ' (', ?, ')')", user.name, user.email)})
        end,
        orderable: false,
        searchable: false,
        live_resource: PasswordlessWeb.Admin.UserLive,
        only: [:show, :edit, :new]
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
        label: "Total orgs",
        class: "w-full lg:w-1/4",
        select: dynamic([o], count(o.id)),
        format: &Integer.to_string/1
      },
      admin: %{
        module: Backpex.Metrics.Value,
        label: "Admin orgs",
        class: "w-full lg:w-1/4",
        select: dynamic([o], o.id |> count() |> filter(:admin in o.tags)),
        format: &Integer.to_string/1
      },
      regular: %{
        module: Backpex.Metrics.Value,
        label: "Customer orgs",
        class: "w-full lg:w-1/4",
        select: dynamic([o], o.id |> count() |> filter(array_length(o.tags) == 0)),
        format: &Integer.to_string/1
      },
      deleted: %{
        module: Backpex.Metrics.Value,
        label: "Deleted orgs",
        class: "w-full lg:w-1/4",
        select: dynamic([o], o.id |> count() |> filter(not is_nil(o.deleted_at))),
        format: &Integer.to_string/1
      }
    ]
  end

  @impl Backpex.LiveResource
  def item_query(query, _live_action, _assigns), do: where(query, [s], is_nil(s.deleted_at) or not is_nil(s.deleted_at))

  @impl Backpex.LiveResource
  def item_actions(default_actions) do
    default_actions
    |> Keyword.drop([:delete])
    |> Enum.concat(
      soft_delete: %{module: SoftDeleteAction},
      soft_recover: %{module: SoftRecoverAction}
    )
  end

  @impl Backpex.LiveResource
  def render_resource_slot(assigns, :index, :page_title) do
    ~H"""
    <.page_header title={@plural_name} />
    """
  end

  @impl Backpex.LiveResource
  def render_resource_slot(assigns, :show, :page_title) do
    ~H"""
    <.page_header title={@singular_name}>
      <.link
        :if={Backpex.LiveResource.can?(assigns, :edit, @item, @live_resource)}
        class="tooltip hover:z-30"
        data-tip={Backpex.translate("Edit")}
        aria-label={Backpex.translate("Edit")}
        patch={Router.get_path(@socket, @live_resource, @params, :edit, @item)}
      >
        <Backpex.HTML.CoreComponents.icon
          name="hero-pencil-square"
          class="h-6 w-6 cursor-pointer transition duration-75 hover:scale-110 hover:text-primary"
        />
      </.link>
    </.page_header>
    """
  end

  @impl Backpex.LiveResource
  def render_resource_slot(assigns, :edit, :page_title) do
    ~H"""
    <.page_header title={Backpex.translate({"Edit %{resource}", %{resource: @singular_name}})} />
    """
  end

  @impl Backpex.LiveResource
  def render_resource_slot(assigns, :new, :page_title) do
    ~H"""
    <.page_header title={@create_button_label} />
    """
  end
end

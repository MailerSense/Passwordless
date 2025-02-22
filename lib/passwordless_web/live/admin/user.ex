defmodule PasswordlessWeb.Admin.UserLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.Accounts.User,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.Accounts.User.changeset/3,
      create_changeset: &Passwordless.Accounts.User.create_changeset/3
    ],
    pubsub: [
      name: Passwordless.PubSub,
      topic: "users",
      event_prefix: "user_"
    ],
    fluid?: true

  import PasswordlessWeb.Components.PageComponents, only: [page_header: 1]

  alias Passwordless.Accounts.User
  alias Passwordless.Security.Guard
  alias Passwordless.Security.Policy.Accounts, as: AccountsPolicy
  alias PasswordlessWeb.Admin.Filters.SoftDelete, as: SoftDeleteFilter
  alias PasswordlessWeb.Admin.ItemActions.ImpersonateUser
  alias PasswordlessWeb.Admin.ItemActions.SoftDelete, as: SoftDeleteAction
  alias PasswordlessWeb.Admin.ItemActions.SoftRecover, as: SoftRecoverAction

  @impl Backpex.LiveResource
  def can?(_assigns, :soft_delete, item), do: is_nil(item.deleted_at)

  @impl Backpex.LiveResource
  def can?(_assigns, :soft_recover, item), do: not is_nil(item.deleted_at)

  @impl Backpex.LiveResource
  def can?(%{current_user: %User{} = impersonator}, :impersonate_user, %User{} = user) do
    Guard.permit(AccountsPolicy, impersonator, :"user.impersonate", user)
  end

  @impl Backpex.LiveResource
  def can?(_assigns, _action, _item), do: true

  @impl Backpex.LiveResource
  def singular_name, do: "User"

  @impl Backpex.LiveResource
  def plural_name, do: "Users"

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
      state: %{
        module: Backpex.Fields.Select,
        label: "State",
        options: fn _assigns -> Enum.map(User.states(), &{String.capitalize(Atom.to_string(&1)), &1}) end,
        index_editable: true
      },
      totp: %{
        module: Backpex.Fields.HasMany,
        only: [:index, :show],
        label: "2FA Enabled",
        select: dynamic([totp: t], t.id),
        display_field: :two_factor_enabled,
        render: &Backpex.Fields.Boolean.render_value/1,
        live_resource: PasswordlessWeb.Admin.TOTPLive
      },
      tokens: %{
        module: Backpex.Fields.HasMany,
        only: [:show],
        label: "Tokens",
        display_field: :context,
        orderable: false,
        searchable: false,
        live_resource: PasswordlessWeb.Admin.TokenLive
      },
      credentials: %{
        module: Backpex.Fields.HasMany,
        only: [:show, :edit, :new],
        label: "Credentials",
        display_field: :provider,
        orderable: false,
        searchable: false,
        live_resource: PasswordlessWeb.Admin.CredentialLive
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
        label: "Total users",
        class: "w-full lg:w-1/5",
        select: dynamic([u], count(u.id)),
        format: &Integer.to_string/1
      },
      active: %{
        module: Backpex.Metrics.Value,
        label: "Active users",
        class: "w-full lg:w-1/5",
        select: dynamic([u], u.id |> count() |> filter(u.state == :active)),
        format: &Integer.to_string/1
      },
      inactive: %{
        module: Backpex.Metrics.Value,
        label: "Inactive users",
        class: "w-full lg:w-1/5",
        select: dynamic([u], u.id |> count() |> filter(u.state == :inactive)),
        format: &Integer.to_string/1
      },
      locked: %{
        module: Backpex.Metrics.Value,
        label: "Locked users",
        class: "w-full lg:w-1/5",
        select: dynamic([u], u.id |> count() |> filter(u.state == :locked)),
        format: &Integer.to_string/1
      },
      deleted: %{
        module: Backpex.Metrics.Value,
        label: "Deleted users",
        class: "w-full lg:w-1/5",
        select: dynamic([u], u.id |> count() |> filter(not is_nil(u.deleted_at))),
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
      soft_recover: %{module: SoftRecoverAction},
      impersonate_user: %{module: ImpersonateUser}
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

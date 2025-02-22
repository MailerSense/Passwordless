defmodule PasswordlessWeb.Admin.CredentialLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.Accounts.Credential,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.Accounts.Credential.changeset/3,
      create_changeset: &Passwordless.Accounts.Credential.changeset/3
    ],
    pubsub: [
      name: Passwordless.PubSub,
      topic: "credentials",
      event_prefix: "credential_"
    ],
    fluid?: true

  import PasswordlessWeb.Components.PageComponents, only: [page_header: 1]

  alias Passwordless.Accounts.Credential

  @impl Backpex.LiveResource
  def singular_name, do: "Credential"

  @impl Backpex.LiveResource
  def plural_name, do: "Credentials"

  @impl Backpex.LiveResource
  def fields do
    [
      id: %{
        label: "ID",
        module: Backpex.Fields.Text,
        only: [:show]
      },
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "User",
        prompt: "Please select a user",
        display_field: :full_name,
        select: dynamic([user: u], fragment("concat(?, ' (', ?, ')')", u.name, u.email)),
        options_query: fn query, _assigns ->
          select_merge(query, [user], %{full_name: fragment("concat(?, ' (', ?, ')')", user.name, user.email)})
        end,
        searchable: true,
        live_resource: PasswordlessWeb.Admin.UserLive,
        index_editable: true
      },
      subject: %{
        label: "Subject",
        module: Backpex.Fields.Text,
        searchable: true
      },
      provider: %{
        module: Backpex.Fields.Select,
        label: "Provider",
        options: fn _assigns -> Enum.map(Credential.providers(), fn {k, v} -> {v, k} end) end,
        index_editable: true
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
      }
    ]
  end

  @impl Backpex.LiveResource
  def metrics do
    [
      total: %{
        module: Backpex.Metrics.Value,
        label: "Total credentials",
        class: "w-full lg:w-1/2",
        select: dynamic([c], count(c.id)),
        format: &Integer.to_string/1
      },
      google: %{
        module: Backpex.Metrics.Value,
        label: "Google credentials",
        class: "w-full lg:w-1/2",
        select: dynamic([c], c.id |> count() |> filter(c.provider == :google)),
        format: &Integer.to_string/1
      }
    ]
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

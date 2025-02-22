defmodule PasswordlessWeb.Org.AuthTokenLive.Index do
  @moduledoc """
  Show a dashboard for a single org. Current user must be a member of the org.
  """
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: AuthToken,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/auth-tokens"))}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/auth-tokens"))}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/app/auth-tokens?#{query_params}")}
  end

  @impl true
  def handle_event("revoke_auth_token", _params, %{assigns: %{auth_token: %AuthToken{} = auth_token}} = socket) do
    case Organizations.revoke_auth_token(auth_token) do
      {:ok, auth_token} ->
        Activity.log(:org, :"org.revoke_auth_token", %{
          org: socket.assigns.current_org,
          user: socket.assigns.current_user,
          name: auth_token.name,
          auth_token: auth_token
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Auth token revoked."))
         |> push_patch(to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/auth-tokens"))
         |> assign_auth_tokens()}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    auth_token = Organizations.get_auth_token!(socket.assigns.current_org, id)

    {:noreply,
     socket
     |> assign(auth_token: auth_token)
     |> assign_filters(params)
     |> assign_auth_tokens(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign_filters(params)
     |> assign_auth_tokens(params)}
  end

  # Private

  defp apply_action(socket, :new) do
    assign(socket,
      page_title: gettext("Create token"),
      page_subtitle: gettext("Generate a new API key for use with your applications")
    )
  end

  defp apply_action(socket, :edit) do
    assign(socket,
      page_title: gettext("Auth token"),
      page_subtitle: gettext("Edit the details of this API key")
    )
  end

  defp apply_action(socket, :reveal) do
    assign(socket,
      page_title: gettext("Auth token"),
      page_subtitle: gettext("Please copy this key and store it somewhere safe")
    )
  end

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Auth tokens"),
      page_subtitle: gettext("Manage your auth token")
    )
  end

  defp apply_action(socket, :revoke) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle:
        gettext("If you revoke this auth token, any applications depending on it may stop working. This is irreversible.")
    )
  end

  defp apply_action(socket, :revoked) do
    assign(socket,
      page_title: gettext("Revoked auth tokens"),
      page_subtitle:
        gettext("These auth tokens have been revoked and are no longer valid for use. You can still view them here.")
    )
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(update_filter_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_auth_tokens(socket, params \\ %{}) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = AuthToken.get_by_org(org)
        {auth_tokens, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, auth_tokens: auth_tokens, meta: meta)

      _ ->
        socket
    end
  end

  attr :value, :string, required: true
  attr :rest, :global, doc: "Any additional HTML attributes to add to the floating container."

  def auth_token_id(assigns) do
    ~H"""
    <div class="flex gap-1 items-center" {@rest}>
      <span class="font-mono break-all line-clamp-1">{@value}</span>
    </div>
    """
  end

  defp state_badge(assigns) do
    assigns =
      assigns
      |> assign(
        :badge_color,
        case assigns.state do
          :active -> "success"
          :revoked -> "danger"
        end
      )
      |> assign(:badge_label, Phoenix.Naming.humanize(assigns.state))

    ~H"""
    <.badge size="sm" label={@badge_label} color={@badge_color} variant="status" with_dot />
    """
  end
end

defmodule PasswordlessWeb.App.MemberLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Invitation
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org
  alias Passwordless.Security.Guard
  alias Passwordless.Security.Policy.Accounts, as: AccountsPolicy
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: Membership,
    default_order: %{
      order_by: [:name],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    changeset = Invitation.changeset(%Invitation{}, %{})
    {:ok, assign_form(socket, changeset)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    membership = Organizations.get_membership!(socket.assigns.current_org, id)

    {:noreply,
     socket
     |> assign(membership: membership)
     |> assign_filters(params)
     |> assign_memberships(params)
     |> apply_action(socket.assigns.live_action, Map.put(params, :membership, membership))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign_filters(params)
     |> assign_memberships(params)}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = DataTable.build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/app/team?#{query_params}")}
  end

  @impl true
  def handle_event("validate_invitation", %{"invitation" => params}, socket) do
    changeset =
      socket.assigns.current_org
      |> Organizations.build_invitation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit_invitation", %{"invitation" => params}, socket) do
    org = socket.assigns.current_org

    case Organizations.create_invitation(org, params) do
      {:ok, invitation} ->
        to =
          if invitation.user_id,
            do: url(~p"/app/invitations"),
            else: url(~p"/auth/sign-up")

        Accounts.Notifier.deliver_org_invitation(org, invitation, to)

        Activity.log(:org, :"org.create_invitation", %{
          user: socket.assigns.current_user,
          org_id: org.id,
          email: invitation.email
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Invitation sent successfully."))
         |> push_patch(to: ~p"/app/team")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_member", %{"id" => id}, socket) do
    org = socket.assigns.current_org
    membership = Organizations.get_membership!(org, id)

    case Organizations.delete_membership(membership) do
      {:ok, membership} ->
        if membership.user_id == socket.assigns.current_user.id do
          {:noreply,
           socket
           |> LiveToast.put_toast(
             :info,
             gettext("You have left %{org_name}!", org_name: org.name)
           )
           |> push_navigate(to: PasswordlessWeb.Helpers.home_path(socket.assigns.current_user))}
        else
          PasswordlessWeb.UserAuth.disconnect_user_liveviews(membership.user)

          {:noreply,
           socket
           |> LiveToast.put_toast(:info, gettext("Member deleted successfully."))
           |> push_patch(to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/team"))}
        end

      {:error, _changeset} ->
        {:noreply,
         socket
         |> LiveToast.put_toast(:error, gettext("Failed to delete member!"))
         |> push_patch(to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/team"))}
    end
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/team")
     )}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/app/team")
     )}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :edit, _params) do
    assign(socket,
      page_title: gettext("Edit teammate"),
      page_subtitle: gettext("View member details and edit their role within your organization")
    )
  end

  defp apply_action(socket, :delete, %{membership: membership}) do
    assign(socket,
      page_title: gettext("Are you sure?"),
      page_subtitle:
        gettext(
          "Are you sure you want to remove %{name} from this organization? They will lose access to all organization resources and will not be able to return unless you invite them again.",
          name: user_name(membership.user)
        )
    )
  end

  defp apply_action(socket, :index, _params) do
    assign(socket,
      page_title: gettext("Team"),
      page_subtitle: gettext("View members of your organization")
    )
  end

  defp apply_action(socket, :invite, _params) do
    assign(socket,
      page_title: gettext("Invite teammate"),
      page_subtitle: gettext("Invite a new user to join your organization")
    )
  end

  defp apply_action(socket, :invitations, _params) do
    assign(socket,
      page_title: gettext("Invitations"),
      page_subtitle: gettext("View users that have been invited to your organization")
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(update_filter_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_memberships(socket, params) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = Membership.get_by_org(org)
        {memberships, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, memberships: memberships, meta: meta)

      _ ->
        socket
    end
  end
end

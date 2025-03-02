defmodule PasswordlessWeb.App.Hooks do
  @moduledoc """
  Org related on_mount hooks used by live views. These are used in the router or within a specific live view if need be.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import Phoenix.Component

  alias Passwordless.Accounts.User
  alias Passwordless.App
  alias Passwordless.Organizations.Org

  def on_mount(:fetch_current_app, _params, session, socket) do
    socket =
      socket
      |> assign_current_app(session)
      |> assign_current_app_user()

    {:cont, socket}
  end

  # Private

  defp assign_current_app(socket, session) do
    assign_new(socket, :current_app, fn ->
      case {socket.assigns[:current_org], session["app_id"]} do
        {%Org{} = org, app_id} when is_binary(app_id) -> Passwordless.get_app!(org, app_id)
        _ -> nil
      end
    end)
  end

  defp assign_current_app_user(%{assigns: %{current_user: %User{}, current_app: %App{} = current_app}} = socket) do
    update(socket, :current_user, fn current_user ->
      %User{current_user | current_app: current_app}
    end)
  end

  defp assign_current_app_user(socket), do: socket
end

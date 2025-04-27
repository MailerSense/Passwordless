defmodule PasswordlessWeb.User.Hooks do
  @moduledoc """
  This module houses on_mount hooks used by live views.
  Docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import Phoenix.Component
  import Phoenix.LiveView

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    case socket.assigns[:current_user] do
      %User{} ->
        {:cont, socket}

      _ ->
        {:halt, redirect(socket, to: ~p"/auth/sign-in")}
    end
  end

  def on_mount(:require_confirmed_user, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    with %User{} = user <- socket.assigns[:current_user], true <- User.confirmed?(user) do
      {:cont, socket}
    else
      _ ->
        socket = put_flash(socket, :error, gettext("You must confirm your email to access this page."))
        {:halt, redirect(socket, to: ~p"/auth/sign-in")}
    end
  end

  def on_mount(:require_admin_user, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    with %User{} = user <- socket.assigns[:current_user], true <- User.confirmed?(user) do
      {:cont, socket}
    else
      _ -> {:halt, redirect(socket, to: "/")}
    end
  end

  def on_mount(:maybe_assign_user, _params, session, socket) do
    {:cont, maybe_assign_user(socket, session)}
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = maybe_assign_user(socket, session)

    case socket.assigns[:current_user] do
      %User{} -> {:halt, redirect(socket, to: "/")}
      _ -> {:cont, socket}
    end
  end

  def on_mount(:assign_current_org, _params, _session, socket) do
    {:cont, maybe_assign_current_org(socket)}
  end

  # Private

  defp maybe_assign_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      session["user_token"]
      |> get_user()
      |> maybe_assign_current_impersonator(session)
    end)
  end

  defp maybe_assign_current_impersonator(%User{} = user, session) do
    case Map.get(session, "impersonator_user_id") do
      user_id when is_binary(user_id) ->
        %User{user | current_impersonator: Accounts.get_user(user_id)}

      _ ->
        user
    end
  end

  defp maybe_assign_current_impersonator(user, _session), do: user

  defp maybe_assign_current_org(
         %{assigns: %{current_user: %User{} = current_user, current_org: %Org{} = current_org}} = socket
       ) do
    assign(socket, :current_user, %User{current_user | current_org: current_org})
  end

  defp maybe_assign_current_org(socket), do: socket

  defp get_user(token) when is_binary(token), do: Accounts.get_user_by_session_token(token)
  defp get_user(_token), do: nil
end

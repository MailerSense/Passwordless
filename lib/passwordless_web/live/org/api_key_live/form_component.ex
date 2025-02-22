defmodule PasswordlessWeb.Org.AuthTokenLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Org
  alias Passwordless.Security.Roles

  @impl true
  def update(assigns, socket) do
    changeset = Organizations.change_auth_token(assigns.auth_token)

    scopes =
      Enum.map(Roles.auth_token_descriptions(), fn {scope, description} ->
        {[
           Phoenix.HTML.raw("<b>#{String.capitalize(Atom.to_string(scope))}:</b> "),
           Phoenix.HTML.raw("<span class=\"text-slate-600 dark:text-slate-300\">#{description}</span>")
         ], scope}
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(scopes: scopes)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"auth_token" => params}, socket) do
    changeset =
      socket.assigns.auth_token
      |> Organizations.change_auth_token(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"auth_token" => auth_token}, socket) do
    save_auth_token(socket, socket.assigns.live_action, auth_token)
  end

  # Private

  defp save_auth_token(%{assigns: %{current_org: %Org{} = org}} = socket, :new, auth_token_params) do
    case Organizations.create_auth_token(org, auth_token_params) do
      {:ok, auth_token, signed_key} ->
        Activity.log(:org, :"org.create_auth_token", %{
          org: socket.assigns.current_org,
          user: socket.assigns.current_user,
          name: auth_token.name,
          auth_token: auth_token
        })

        Cache.put(auth_token.id, signed_key, ttl: :timer.minutes(5))

        {:noreply, push_navigate(socket, to: ~p"/app/auth-tokens/#{auth_token}/reveal")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_auth_token(%{assigns: %{auth_token: %AuthToken{} = auth_token}} = socket, :edit, auth_token_params) do
    case Organizations.update_auth_token(auth_token, auth_token_params) do
      {:ok, auth_token} ->
        Activity.log(:org, :"org.update_auth_token", %{
          org: socket.assigns.current_org,
          user: socket.assigns.current_user,
          name: auth_token.name,
          auth_token: auth_token
        })

        {:noreply,
         socket
         |> put_flash(:info, gettext("Auth token updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end

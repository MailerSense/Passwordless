defmodule PasswordlessWeb.App.MethodLive.MagicLink do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    magic_link = Repo.preload(app, :magic_link).magic_link
    domain = Repo.preload(app, :domain).domain
    changeset = Passwordless.change_magic_link(magic_link)

    email_template = Repo.preload(magic_link, :email_template).email_template
    email_version = Passwordless.get_email_template_version(email_template, :en)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       magic_link: magic_link,
       domain: domain,
       email_template: email_template,
       email_version: email_version
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"magic_link" => magic_link_params}, socket) do
    save_magic_link(socket, magic_link_params)
  end

  @impl true
  def handle_event("validate", %{"magic_link" => magic_link_params}, socket) do
    save_magic_link(socket, magic_link_params)
  end

  # Private

  defp save_magic_link(socket, params) do
    case Passwordless.update_magic_link(socket.assigns.magic_link, params) do
      {:ok, magic_link} ->
        changeset =
          magic_link
          |> Passwordless.change_magic_link()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(magic_link: magic_link)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end
end

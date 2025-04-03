defmodule PasswordlessWeb.App.AuthenticatorLive.Email do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, [:email])

    email = app.email
    domain = Passwordless.get_app_email_domain!(app)
    changeset = Passwordless.change_email(email)

    email_template = Repo.preload(email, :email_template).email_template
    email_version = Passwordless.get_email_template_version(email_template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       email: email,
       domain: domain,
       email_template: email_template,
       email_version: email_version
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"email" => email_params}, socket) do
    save_email(socket, email_params)
  end

  @impl true
  def handle_event("validate", %{"email" => email_params}, socket) do
    save_email(socket, email_params)
  end

  # Private

  defp save_email(socket, params) do
    opts = [domain: socket.assigns[:domain]]

    case Passwordless.update_email(socket.assigns.email, params, opts) do
      {:ok, email} ->
        changeset =
          email
          |> Passwordless.change_email()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(email: email)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
    |> assign(email_tracking: Ecto.Changeset.fetch_field!(changeset, :email_tracking))
  end
end

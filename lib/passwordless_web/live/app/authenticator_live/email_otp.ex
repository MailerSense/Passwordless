defmodule PasswordlessWeb.App.AuthenticatorLive.EmailOTP do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Email.Renderer
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, [:email_otp])

    email_otp = app.email_otp
    domain = Passwordless.get_email_domain!(app)
    changeset = Passwordless.change_email_otp(email_otp)

    email_template = Repo.preload(email_otp, :email_template).email_template
    email_template_locale = Passwordless.get_email_template_locale(email_template)

    socket =
      case Renderer.render(email_template_locale, Renderer.demo_variables(), [{:app, app} | Renderer.demo_opts()]) do
        {:ok, %{html_content: html_content}} ->
          assign(socket, preview: html_content)

        {:error, _} ->
          assign(socket, preview: email_template_locale.html_body)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       domain: domain,
       email_otp: email_otp,
       email_template: email_template
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"email_otp" => email_params}, socket) do
    save_email(socket, email_params)
  end

  @impl true
  def handle_event("validate", %{"email_otp" => email_params}, socket) do
    save_email(socket, email_params)
  end

  # Private

  defp save_email(socket, params) do
    opts = [domain: socket.assigns[:domain]]

    case Passwordless.update_email_otp(socket.assigns.email_otp, params, opts) do
      {:ok, email_otp} ->
        changeset =
          email_otp
          |> Passwordless.change_email_otp()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(email_otp: email_otp)
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

defmodule PasswordlessWeb.Auth.PasswordLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_form(build_login_changeset())
      |> assign(email: Phoenix.Flash.get(socket.assigns.flash, :email))
      |> assign(page_title: gettext("Sign In"))

    {:ok, socket, temporary_assigns: [email: nil]}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      user_params
      |> build_login_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event(_action, _params, socket) do
    {:noreply, socket}
  end

  defp build_login_changeset(params \\ %{}) do
    types = %{
      email: :string,
      password: :string
    }

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Database.ChangesetExt.validate_email()
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :user))
  end
end

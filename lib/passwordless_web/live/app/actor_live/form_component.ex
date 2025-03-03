defmodule PasswordlessWeb.App.ActorLive.FormComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Actor

  @impl true
  def update(%{actor: %Actor{} = actor} = assigns, socket) do
    changeset = Passwordless.change_actor(actor)
    languages = Enum.map(Passwordless.Locale.languages(), fn {code, name} -> {name, code} end)

    country_codes =
      ExPhoneNumber.Metadata.get_supported_regions()
      |> Enum.map(fn code ->
        code = String.downcase(code)
        country = Keyword.get(Passwordless.Locale.countries(), String.to_atom(code))

        if country do
          country_code = ExPhoneNumber.Metadata.get_country_code_for_region_code(code)
          {"#{country} (+#{country_code})", code}
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort(fn {name1, _}, {name2, _} -> name1 < name2 end)

    flag_mapping = fn
      nil -> "flag-#{elem(List.first(country_codes), 1)}"
      code -> "flag-#{code}"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(languages: languages, country_codes: country_codes, flag_mapping: flag_mapping)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"actor" => actor_params}, socket) do
    changeset =
      socket.assigns.actor
      |> Passwordless.change_actor(actor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"actor" => actor_params}, socket) do
    save_actor(socket, socket.assigns.live_action, actor_params)
  end

  # Private

  defp save_actor(socket, :edit, actor_params) do
    app = socket.assigns.current_app
    actor = socket.assigns.actor

    case Passwordless.update_actor(app, actor, actor_params) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Actor updated."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_actor(socket, :new, actor_params) do
    case Passwordless.create_actor(socket.assigns.current_app, actor_params) do
      {:ok, _actor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Actor created."))
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end
end

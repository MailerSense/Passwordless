defmodule PasswordlessWeb.App.EmbedLive.API do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    changeset = Passwordless.change_app(app)

    actions =
      Enum.map(App.actions(), fn action ->
        {Phoenix.Naming.humanize(action), action}
      end)

    icon_mapping = fn
      nil -> "remix-checkbox-circle-fill"
      "allow" -> "remix-checkbox-circle-fill"
      :allow -> "remix-checkbox-circle-fill"
      "block" -> "remix-close-circle-fill"
      :block -> "remix-close-circle-fill"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       actions: actions,
       icon_mapping: icon_mapping
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    addresses =
      changeset
      |> Ecto.Changeset.get_field(:whitelisted_ip_addresses, [])
      |> Enum.map(fn %App.IPAddress{address: addr} -> Util.CIDR.parse(addr) end)
      |> Enum.filter(&match?(%Util.CIDR{}, &1))
      |> Enum.map(fn %Util.CIDR{first: first, last: last, hosts: hosts} ->
        {format_ip(first), format_ip(last), hosts}
      end)

    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: Ecto.Changeset.get_field(changeset, :default_action))
    |> assign(whitelist_ip_access: Ecto.Changeset.get_field(changeset, :whitelist_ip_access))
    |> assign(whitelisted_ip_addresses: addresses)
  end

  defp format_ip(ip), do: String.pad_trailing(to_string(:inet.ntoa(ip)), 16)
end

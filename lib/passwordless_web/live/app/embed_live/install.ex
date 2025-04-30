defmodule PasswordlessWeb.App.EmbedLive.Install do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.AuthToken
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, :settings)
    changeset = Passwordless.change_app(app)

    case Repo.preload(app, :auth_token) do
      %App{auth_token: %AuthToken{} = auth_token} ->
        keys = [
          %{
            id: "app_id",
            name: gettext("App ID"),
            token: app.id,
            inserted_at: app.inserted_at
          },
          %{
            id: "app_secret",
            name: gettext("Secret Key"),
            token: AuthToken.preview(auth_token),
            inserted_at: auth_token.inserted_at
          }
        ]

        {:ok,
         socket
         |> assign(assigns)
         |> assign(
           app: app,
           keys: keys,
           reveal_secret?: false,
           secret: AuthToken.encode(auth_token)
         )
         |> assign_form(changeset)}

      _ ->
        keys = [
          %{
            id: "app_id",
            name: gettext("App ID"),
            token: app.id,
            inserted_at: app.inserted_at
          }
        ]

        {:ok,
         socket
         |> assign(assigns)
         |> assign(app: app, keys: keys, reveal_secret?: false, secret: nil)
         |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("toggle_reveal_secret", _params, socket) do
    {:noreply, update(socket, :reveal_secret?, &Kernel.not/1)}
  end

  @impl true
  def handle_event(event, %{"app" => app_params}, socket) when event in ["save", "validate"] do
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
    settings = Ecto.Changeset.get_field(changeset, :settings)

    addresses =
      settings.allowlisted_ip_addresses
      |> Enum.map(fn %AppSettings.IPAddress{address: addr} -> Util.CIDR.parse(addr) end)
      |> Enum.filter(&match?(%Util.CIDR{}, &1))
      |> Enum.map(fn %Util.CIDR{first: first, last: last, hosts: hosts} ->
        {format_ip(first), format_ip(last), hosts}
      end)

    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: settings.default_action)
    |> assign(allowlist_api_access: settings.allowlist_api_access)
    |> assign(allowlisted_ip_addresses: addresses)
  end

  defp format_ip(ip), do: String.pad_trailing(to_string(:inet.ntoa(ip)), 16)
end

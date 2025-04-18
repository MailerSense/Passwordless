defmodule PasswordlessWeb.App.EmbedLive.Install do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Repo

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
            name: gettext("App Secret"),
            token: AuthToken.preview(auth_token),
            inserted_at: auth_token.inserted_at
          }
        ]

        {:ok,
         socket
         |> assign(assigns)
         |> assign(
           actions: actions,
           icon_mapping: icon_mapping,
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
         |> assign(actions: actions, icon_mapping: icon_mapping, keys: keys, reveal_secret?: false, secret: nil)
         |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("toggle_reveal_secret", _params, socket) do
    {:noreply, update(socket, :reveal_secret?, &Kernel.not/1)}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    changeset =
      socket.assigns.app
      |> Passwordless.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: Ecto.Changeset.get_field(changeset, :default_action))
  end
end

defmodule PasswordlessWeb.App.EmbedLive.Fingerprint do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, :settings)
    changeset = Passwordless.change_app(app)

    actions =
      Enum.map(AppSettings.actions(), fn action ->
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
       app: app,
       actions: actions,
       icon_mapping: icon_mapping
     )
     |> assign_form(changeset)}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    settings = Ecto.Changeset.get_field(changeset, :settings)

    socket
    |> assign(form: to_form(changeset))
    |> assign(default_action: settings.default_action)
  end
end

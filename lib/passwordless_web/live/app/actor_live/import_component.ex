defmodule PasswordlessWeb.App.ActorLive.ImportComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.FileUploads

  @impl true
  def update(assigns, socket) do
    upload_opts =
      FileUploads.prepare(
        accept: ~w(.csv .xlsx .xls),
        max_entries: 1,
        max_file_size: 5_242_880 * 2
      )

    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:actors, upload_opts)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end

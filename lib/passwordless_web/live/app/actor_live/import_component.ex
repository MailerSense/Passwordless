defmodule PasswordlessWeb.App.ActorLive.ImportComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @upload_provider :passwordless |> Application.compile_env!(:media_upload) |> Keyword.fetch!(:adapter)

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:actors,
       accept: ~w(.csv .xlsx .xls),
       max_entries: 1,
       max_file_size: 5_242_880 * 2
     )}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end
end

defmodule PasswordlessWeb.App.HomeLive.ViewComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end

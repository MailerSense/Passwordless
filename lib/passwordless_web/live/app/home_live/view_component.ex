defmodule PasswordlessWeb.App.HomeLive.ViewComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Action
  alias Passwordless.Repo

  @impl true
  def update(%{action: %Action{} = action} = assigns, socket) do
    action =
      Repo.preload(action, [
        :events,
        {:challenge, [:email_message]},
        actor: [:email, :phone]
      ])

    {:ok, socket |> assign(assigns) |> assign(action: action)}
  end
end

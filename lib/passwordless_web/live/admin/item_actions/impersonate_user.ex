defmodule PasswordlessWeb.Admin.ItemActions.ImpersonateUser do
  @moduledoc false

  use BackpexWeb, :item_action
  use PasswordlessWeb, :verified_routes

  alias Passwordless.Accounts.User

  @impl Backpex.ItemAction
  def icon(assigns, _item) do
    ~H"""
    <Backpex.HTML.CoreComponents.icon
      name="hero-user-circle"
      class="h-5 w-5 cursor-pointer transition duration-75 hover:scale-110 hover:text-success-600"
    />
    """
  end

  @impl Backpex.ItemAction
  def label(_assigns, _item), do: "Impersonate"

  @impl Backpex.ItemAction
  def confirm_label(_assigns), do: "Impersonate"

  @impl Backpex.ItemAction
  def cancel_label(_assigns), do: "Cancel"

  @impl Backpex.ItemAction
  def handle(socket, items, _data) do
    socket =
      case items do
        [%User{} = user] ->
          redirect(socket, to: ~p"/admin/impersonate/#{user.id}")

        _ ->
          socket
      end

    {:noreply, socket}
  end
end

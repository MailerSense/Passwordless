defmodule PasswordlessWeb.Admin.ItemActions.SoftRecover do
  @moduledoc false

  use BackpexWeb, :item_action

  alias Passwordless.Repo

  require Logger

  @impl Backpex.ItemAction
  def icon(assigns, _item) do
    ~H"""
    <Backpex.HTML.CoreComponents.icon
      name="hero-folder-plus"
      class="h-5 w-5 cursor-pointer transition duration-75 hover:scale-110 hover:text-success-600"
    />
    """
  end

  @impl Backpex.ItemAction
  def label(_assigns, _item), do: Backpex.translate("Soft Recover")

  @impl Backpex.ItemAction
  def confirm_label(_assigns), do: Backpex.translate("Soft Recover")

  @impl Backpex.ItemAction
  def cancel_label(_assigns), do: Backpex.translate("Cancel")

  @impl Backpex.ItemAction
  def confirm(assigns) do
    count = Enum.count(assigns.selected_items)

    if count > 1 do
      Backpex.translate(
        {"Do you want to soft recover these %{count} %{resources}?", %{count: count, resources: assigns.plural_name}}
      )
    else
      Backpex.translate({"Do you want to soft recover this %{resource}?", %{resource: assigns.singular_name}})
    end
  end

  @impl Backpex.ItemAction
  def handle(socket, items, _data) do
    socket =
      try do
        {:ok, _items} =
          Repo.with_soft_deleted(fn ->
            Backpex.Resource.update_all(items, [set: [deleted_at: nil]], "updated", socket.assigns.live_resource)
          end)

        socket
        |> clear_flash()
        |> put_flash(:info, success_message(socket.assigns, items))
      rescue
        error ->
          Logger.error("An error occurred while soft recovering the resource: #{inspect(error)}")

          socket
          |> clear_flash()
          |> put_flash(:error, error_message(socket.assigns, error, items))
      end

    {:noreply, socket}
  end

  defp success_message(assigns, [_item]) do
    Backpex.translate({"%{resource} has been soft recovered successfully.", %{resource: assigns.singular_name}})
  end

  defp success_message(assigns, items) do
    Backpex.translate(
      {"%{count} %{resources} have been soft recovered successfully.",
       %{resources: assigns.plural_name, count: Enum.count(items)}}
    )
  end

  defp error_message(assigns, %Postgrex.Error{postgres: %{code: :foreign_key_violation}}, [_item] = items) do
    "#{error_message(assigns, :error, items)} #{Backpex.translate("The item is used elsewhere.")}"
  end

  defp error_message(assigns, %Ecto.ConstraintError{type: :foreign_key}, [_item] = items) do
    "#{error_message(assigns, :error, items)} #{Backpex.translate("The item is used elsewhere.")}"
  end

  defp error_message(assigns, %Postgrex.Error{postgres: %{code: :foreign_key_violation}}, items) do
    "#{error_message(assigns, :error, items)} #{Backpex.translate("The items are used elsewhere.")}"
  end

  defp error_message(assigns, %Ecto.ConstraintError{type: :foreign_key}, items) do
    "#{error_message(assigns, :error, items)} #{Backpex.translate("The items are used elsewhere.")}"
  end

  defp error_message(assigns, _error, [_item]) do
    Backpex.translate({"An error occurred while soft recovering the %{resource}!", %{resource: assigns.singular_name}})
  end

  defp error_message(assigns, _error, items) do
    Backpex.translate(
      {"An error occurred while soft recovering %{count} %{resources}!",
       %{resources: assigns.plural_name, count: Enum.count(items)}}
    )
  end
end

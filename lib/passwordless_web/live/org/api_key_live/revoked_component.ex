defmodule PasswordlessWeb.Org.AuthTokenLive.RevokedComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: AuthToken,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_auth_tokens()}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  attr :value, :string, required: true
  attr :rest, :global, doc: "Any additional HTML attributes to add to the floating container."

  def auth_token_id(assigns) do
    ~H"""
    <div class="flex gap-1 items-center" {@rest}>
      <span class="font-mono break-all line-clamp-1">{@value}</span>
    </div>
    """
  end

  defp assign_auth_tokens(socket) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query =
          org
          |> AuthToken.get_by_org()
          |> AuthToken.get_revoked()

        {auth_tokens, meta} = DataTable.search(query, %{}, @data_table_opts)
        assign(socket, auth_tokens: auth_tokens, meta: meta)

      _ ->
        socket
    end
  end
end

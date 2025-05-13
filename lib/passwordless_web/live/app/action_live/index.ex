defmodule PasswordlessWeb.App.ActionLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Database.Tenant
  alias Passwordless.ActionTemplate
  alias Passwordless.App
  alias PasswordlessWeb.Components.DataTable

  @data_table_opts [
    for: ActionTemplate,
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{current_app: %App{} = current_app}} = socket) do
    action_template =
      case params do
        %{"id" => id} -> Passwordless.get_action_template!(current_app, id)
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(action_template: action_template)
     |> assign_filters(params)
     |> assign_actions(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/actions")
     )}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply,
     push_patch(socket,
       to: apply_filters(socket.assigns.filters, socket.assigns.meta, ~p"/actions")
     )}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/actions")}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    filtered? =
      case Flop.validate(filter_params) do
        {:ok, %Flop{} = flop} -> Enum.any?(flop.filters, fn x -> x.value end)
        _ -> false
      end

    to =
      if filtered? do
        ~p"/actions?#{build_filter_params(socket.assigns.meta, filter_params)}"
      else
        ~p"/actions"
      end

    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("delete_action_template", _params, socket) do
    action_template = socket.assigns.action_template

    case Passwordless.delete_action_template(action_template) do
      {:ok, _action_template} ->
        {:noreply,
         socket
         |> put_toast(:info, gettext("Action has been deleted."), title: gettext("Success"))
         |> push_navigate(to: ~p"/actions")}

      _ ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete action!"), title: gettext("Error"))
         |> push_patch(to: ~p"/actions")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :new) do
    assign(socket,
      page_title: gettext("Create action"),
      page_subtitle:
        gettext(
          "Actions are the building blocks that let you create contextual, risk-based authentication flows that enhance security without sacrificing user experience."
        )
    )
  end

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Rules"),
      page_subtitle: gettext("Manage your rules")
    )
  end

  defp apply_action(socket, :delete) do
    assign(socket,
      page_title: gettext("Delete action"),
      page_subtitle:
        gettext(
          "Are you sure you want to delete this action? This action will be permanently deleted, and all widgets or API integrations using this action will stop working."
        )
    )
  end

  defp apply_action(socket, :run_test) do
    assign(socket,
      page_title: gettext("Run test"),
      page_subtitle:
        gettext(
          "Test your actions by running them against a test user. This way, you can see how the action will behave in a real-world scenario."
        )
    )
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(DataTable.build_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_filters(socket, params) do
    assign(socket, filters: Map.take(params, ~w(page filters order_by order_directions)))
  end

  defp assign_actions(socket, params) when is_map(params) do
    app = socket.assigns.current_app
    opts = [prefix: Tenant.to_prefix(app)]

    query =
      app
      |> ActionTemplate.get_by_app()
      |> ActionTemplate.join_adapter_opts(opts)

    {actions, meta} = DataTable.search(query, params, @data_table_opts)
    assign(socket, actions: actions, meta: meta)
  end

  defp generate_data(num_bars, max_series_per_bar) do
    Enum.map(1..num_bars, fn _ ->
      num_series = :rand.uniform(max_series_per_bar)
      Enum.zip(random_colors(num_series), generate_percentages(num_series))
    end)
  end

  # Generates random percentages that sum up to 1.0
  defp generate_percentages(count) do
    random_values = Enum.map(1..count, fn _ -> :rand.uniform() end)
    total = Enum.sum(random_values)
    Enum.map(random_values, fn value -> value / total end)
  end

  # Generates a random color in hex format
  defp random_colors(num_series) do
    [100, 100, 100, 100, 100, 100, 100, 100, 100, 200, 300]
    |> Enum.shuffle()
    |> Enum.take(num_series)
  end
end

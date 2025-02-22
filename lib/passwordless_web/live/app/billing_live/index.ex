defmodule PasswordlessWeb.App.BillingLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Activity.Log
  alias Passwordless.Billing
  alias Passwordless.Organizations.Org
  alias PasswordlessWeb.Components.DataTable
  alias PasswordlessWeb.Product

  @data_table_opts [
    for: Log,
    default_order: %{
      order_by: [:id],
      order_directions: [:desc]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_filters(params)
     |> assign_logs(params)
     |> assign_config()
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/billing")}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/app/billing")}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    flop =
      case Flop.validate(filter_params) do
        {:ok, %Flop{} = flop} -> flop
        _ -> nil
      end

    filtered? = flop && Enum.any?(flop.filters, fn x -> x.value end)

    socket = assign(socket, current_flop: flop)

    if filtered? do
      {:noreply,
       push_patch(socket, to: ~p"/app/billing?#{DataTable.build_filter_params(socket.assigns.meta, filter_params)}")}
    else
      {:noreply, push_patch(socket, to: ~p"/app/billing")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_logs, {:ok, %{logs: logs, meta: meta, cursor: cursor}}, socket) do
    socket = assign(socket, meta: meta, cursor: cursor, loading: false, finished: Enum.empty?(logs))
    socket = Enum.reduce(logs, socket, fn log, socket -> stream_insert(socket, :logs, log) end)

    {:noreply, socket}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Billing"),
      page_subtitle: gettext("Manage your billing")
    )
  end

  defp assign_config(socket) do
    config =
      case Billing.get_current_plan(socket.assigns.current_org) do
        :free ->
          %{
            free: %{
              button_text: gettext("Current Plan"),
              button_color: "light",
              chosen: true
            },
            business: %{
              button_text: gettext("Start free 14-day trial"),
              button_color: "secondary",
              chosen_checks: 5
            },
            enterprise: %{
              button_text: gettext("Contact us")
            },
            chosen: :free
          }

        {:paid, :business, chosen_checks} when is_integer(chosen_checks) ->
          %{
            free: %{
              button_text: gettext("Downgrade"),
              action_button_color: "gray",
              action_button_variant: "solid"
            },
            business: %{
              button_text: gettext("Open Stripe Dashboard"),
              chosen_checks: chosen_checks,
              action_button_color: "secondary",
              action_button_variant: "solid",
              chosen: true
            },
            enterprise: %{
              button_text: gettext("Contact us")
            },
            chosen: :business
          }

        {:trial, :business, chosen_checks, trial_days_remaining}
        when is_integer(chosen_checks) and is_integer(trial_days_remaining) ->
          %{
            free: %{
              button_text: gettext("Downgrade"),
              action_button_color: "gray",
              action_button_variant: "solid"
            },
            business: %{
              button_text: ngettext("1 day of trial remaining", "%{count} days of trial remaining", trial_days_remaining),
              action_button_color: "secondary",
              action_button_variant: "solid",
              chosen_checks: chosen_checks,
              chosen: true
            },
            enterprise: %{
              button_text: gettext("Contact us")
            }
          }
      end

    plans = Map.new(Product.pricing_plans2(), fn %{kind: kind} = plan -> {kind, plan} end)

    assign(socket, plans: plans, billing: config)
  end

  defp apply_filters(filters, %Flop.Meta{} = meta, path)
       when is_map(filters) and map_size(filters) > 0 and is_binary(path) do
    path <> "?" <> Plug.Conn.Query.encode(DataTable.build_params(meta, filters))
  end

  defp apply_filters(_filters, _meta, path) when is_binary(path), do: path

  defp assign_logs(socket, params) do
    case socket.assigns[:current_org] do
      %Org{} = org ->
        query = Log.get_by_org(Log, org)

        {logs, meta} = DataTable.search(query, params, @data_table_opts)
        assign(socket, logs: logs, meta: meta)

      _ ->
        socket
    end
  end

  defp assign_filters(socket, params) do
    params = Map.take(params, ~w(filters order_by order_directions))

    flop =
      case Flop.validate(params) do
        {:ok, %Flop{} = flop} -> flop
        _ -> nil
      end

    assign(socket, filters: params, last_flop: flop)
  end
end

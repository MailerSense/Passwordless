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
     |> assign_logs(params)
     |> assign_config()
     |> assign_stats()
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/billing")}
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

  defp assign_stats(socket) do
    users = Passwordless.get_app_user_count_cached(socket.assigns.current_app)
    mau = Passwordless.get_app_mau_count_cached(socket.assigns.current_app, Date.utc_today())
    apps = socket.assigns.current_org |> Passwordless.Organizations.list_apps() |> Enum.map(& &1.name)

    assign(socket, apps: apps, user_count: users, mau_count: mau)
  end
end

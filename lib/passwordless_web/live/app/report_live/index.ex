defmodule PasswordlessWeb.App.ReportLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/reports")}
  end

  @impl true
  def handle_event("close_slide_over", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/reports")}
  end

  @impl true
  def handle_event("send_geo_data", _params, socket) do
    app = socket.assigns.current_app
    today = DateTime.utc_now()
    span_start = Timex.shift(today, hours: -30)
    span_end = today

    interval =
      Timex.Interval.new(
        from: span_start,
        until: span_end
      )

    {:noreply, start_async(socket, :load_geo_data, fn -> Passwordless.get_reporting_events(app, interval) end)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_async(:load_geo_data, {:ok, geo_data}, socket) do
    {:noreply, push_event(socket, :get_geo_data, %{geo_data: geo_data})}
  end

  # Private

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Reports"),
      page_subtitle: gettext("Manage your reports")
    )
  end
end

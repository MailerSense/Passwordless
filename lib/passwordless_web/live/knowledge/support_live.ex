defmodule PasswordlessWeb.Knowledge.SupportLive do
  @moduledoc """
  Allows for sending bulk emails to a list of recipients.
  """
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: gettext("Support"))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout
      current_user={@current_user}
      current_page={:support}
      current_section={:knowledge}
      padded={false}
    >
      <!-- Google Calendar Appointment Scheduling begin -->
      <iframe
        src="https://calendar.google.com/calendar/appointments/schedules/AcZssZ0J0sOtX7EaVn6TSsIoX9I21N4MYL8je0fe2BVWcEjKnaSPYbQ__3tV51kAldFrNigFqr6l_pzk?gv=true"
        style="border: 0;"
        class="bg-white h-screen"
        width="100%"
        frameborder="0"
      >
      </iframe>
      <!-- end Google Calendar Appointment Scheduling -->
    </.layout>
    """
  end
end

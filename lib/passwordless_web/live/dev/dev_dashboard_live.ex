defmodule PasswordlessWeb.DevDashboardLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Dev")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_user={@current_user} current_page={:dev_routes} current_section={:dev}>
      <div class="px-6 xl:px-8 py-6">
        <.page_header title={Passwordless.config(:app_name)}></.page_header>
        <.p no_margin>A list of your apps routes. Click one to copy its helper.</.p>
        <.box class="mt-6">
          <.route_tree router={PasswordlessWeb.Router} />
        </.box>
      </div>
    </.layout>
    """
  end
end

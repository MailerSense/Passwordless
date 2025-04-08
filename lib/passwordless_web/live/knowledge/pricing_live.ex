defmodule PasswordlessWeb.Knowledge.PricingLive do
  @moduledoc """
  Allows for sending bulk emails to a list of recipients.
  """
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: gettext("Pricing"))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_user={@current_user} current_page={:pricing} current_section={:knowledge}>
    </.layout>
    """
  end
end

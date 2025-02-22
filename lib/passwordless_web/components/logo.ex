defmodule PasswordlessWeb.Components.Logo do
  @moduledoc """
  A component to display the app logo.
  """

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes

  # SETUP_TODO
  # This module relies on the following images. Replace these images with your logos.
  # We created a Figma file to easily create and import these assets: https://www.figma.com/community/file/1139155923924401853
  # /priv/static/images/logo_dark.svg
  # /priv/static/images/logo_light.svg
  # /priv/static/images/logo_icon_dark.svg
  # /priv/static/images/logo_icon_light.svg
  # /priv/static/images/favicon.png
  # /priv/static/images/open-graph.png

  @doc "Displays your full logo. "

  attr :class, :string, default: "h-10"
  attr :variant, :string, default: "both", values: ["dark", "light", "both"]

  def logo(assigns) do
    assigns = assign_new(assigns, :logo_file, fn -> "logo_#{assigns[:variant]}.svg" end)

    ~H"""
    <%= if Enum.member?(["light", "dark"], @variant) do %>
      <img
        class={@class}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/#{@logo_file}")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
    <% else %>
      <img
        class={[@class, "block dark:hidden"]}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/logo_dark.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
      <img
        class={[@class, " hidden dark:block"]}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/logo_light.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
    <% end %>
    """
  end

  @doc "Displays just the icon part of your logo"

  attr :class, :string, default: "h-9 w-9"
  attr :variant, :string, default: "both", values: ["dark", "light", "both"]

  def logo_icon(assigns) do
    assigns = assign_new(assigns, :logo_file, fn -> "logo_icon_#{assigns[:variant]}.svg" end)

    ~H"""
    <%= if Enum.member?(["light", "dark"], @variant) do %>
      <img
        class={@class}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/#{@logo_file}")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
    <% else %>
      <img
        class={@class <> " block dark:hidden"}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/logo_icon_dark.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
      <img
        class={@class <> " hidden dark:block"}
        src={static_url(PasswordlessWeb.Endpoint, ~p"/images/logo_icon_light.svg")}
        alt={Passwordless.config(:app_name)}
        title={Passwordless.config(:app_name)}
      />
    <% end %>
    """
  end

  def logo_for_emails(assigns) do
    ~H"""
    <img height="60" src={Passwordless.config(:logo_url_for_emails)} />
    """
  end
end

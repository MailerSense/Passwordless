defmodule PasswordlessWeb.SettingsLayoutComponent do
  @moduledoc """
  A layout for any user setting screen like "Change email", "Change password" etc
  """
  use PasswordlessWeb, :component

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership

  attr :current_user, :map, required: true
  attr :current_page, :atom, required: true
  attr :inner_class, :any, default: ""
  slot :action, required: false
  slot :inner_block

  def tabbed_settings_layout(assigns) do
    assigns = assign_new(assigns, :menu_items, fn -> menu_items(assigns[:current_user]) end)

    ~H"""
    <.layout
      current_user={@current_user}
      current_page={:settings}
      current_section={:app}
      current_subpage={@current_page}
      padded={false}
    >
      <.pilled_layout current_page={@current_page} menu_items={@menu_items}>
        <:header>
          <.page_header title={gettext("Settings")} />
        </:header>
        {render_slot(@inner_block)}
      </.pilled_layout>
    </.layout>
    """
  end

  # Private

  defp menu_items(%User{current_membership: %Membership{}} = user) do
    org_routes = [:app_settings, :team, :domain, :organization]

    user_routes = [
      :edit_profile,
      :org_invitations
    ]

    user_routes =
      if Organizations.has_open_invitations?(user),
        do: user_routes,
        else: user_routes -- [:org_invitations]

    PasswordlessWeb.Menus.build_menu(
      org_routes ++ user_routes,
      user
    )
  end

  defp menu_items(%User{} = user) do
    PasswordlessWeb.Menus.build_menu(
      [
        :edit_profile,
        :edit_totp,
        :edit_password,
        :org_invitations
      ],
      user
    )
  end
end

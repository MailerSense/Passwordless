defmodule PasswordlessWeb.SettingsLayoutComponent do
  @moduledoc """
  A layout for any user setting screen like "Change email", "Change password" etc
  """
  use PasswordlessWeb, :component

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership

  attr :current_user, :map, required: true
  attr :current_page, :atom
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
    >
      <.tabbed_layout current_page={@current_page} menu_items={@menu_items}>
        <.page_header title={PasswordlessWeb.Menus.translate_item(@current_page, @current_user)}>
          {render_slot(@action)}
        </.page_header>
        {render_slot(@inner_block)}
      </.tabbed_layout>
    </.layout>
    """
  end

  # Private

  defp menu_items(%User{current_membership: %Membership{}} = user) do
    org_routes = [:apps, :team, :billing, :organization]

    user_routes = [
      :edit_profile,
      :edit_totp,
      :edit_password,
      :org_invitations
    ]

    user_routes =
      if user |> Organizations.list_invitations_by_user() |> Enum.empty?(),
        do: user_routes -- [:org_invitations],
        else: user_routes

    PasswordlessWeb.Menus.build_menu(
      user_routes ++ org_routes,
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

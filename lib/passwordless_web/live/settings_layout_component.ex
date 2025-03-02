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
  slot :action, required: false
  slot :inner_block

  def tabbed_settings_layout(assigns) do
    assigns =
      assigns
      |> assign_new(:menu_items, fn -> menu_items(assigns[:current_user]) end)
      |> assign_new(:org_menu_items, fn -> PasswordlessWeb.Helpers.org_menu_items(assigns[:current_user]) end)

    ~H"""
    <.layout current_user={@current_user} current_page={:settings} current_section={:app}>
      <.page_header title={gettext("Settings")}>
        <.dropdown
          size="lg"
          label={PasswordlessWeb.Helpers.user_org_name(@current_user)}
          label_icon="remix-building-line"
        >
          <.dropdown_menu_item link_type="live_redirect" to={~p"/app/organization/new"}>
            <.icon name="remix-add-line" class="w-5 h-5" />
            {gettext("New organization")}
          </.dropdown_menu_item>
          <.form :for={org <- @org_menu_items} for={nil} action={~p"/app/org/switch"} method="post">
            <.input type="hidden" name="org_id" value={org.id} />
            <button class="pc-dropdown__menu-item">
              <.icon name="remix-building-line" class="w-5 h-5" />
              <span class="line-clamp-1">{org.name}</span>
            </button>
          </.form>
        </.dropdown>
      </.page_header>
      <.tabbed_layout current_page={@current_page} menu_items={@menu_items} inner_class="p-6">
        {render_slot(@inner_block)}
      </.tabbed_layout>
    </.layout>
    """
  end

  # Private

  defp menu_items(%User{current_membership: %Membership{}} = user) do
    org_routes = [:app, :team, :billing, :domain, :organization]

    user_routes = [
      :edit_profile,
      :edit_totp,
      :edit_password,
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

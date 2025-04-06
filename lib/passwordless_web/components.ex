defmodule PasswordlessWeb.Components do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import PasswordlessWeb.Components.Accordion
      import PasswordlessWeb.Components.Alert
      import PasswordlessWeb.Components.AuthLayout
      import PasswordlessWeb.Components.Avatar
      import PasswordlessWeb.Components.Badge
      import PasswordlessWeb.Components.BadgeSelect
      import PasswordlessWeb.Components.Button
      import PasswordlessWeb.Components.Card
      import PasswordlessWeb.Components.ComboBox
      import PasswordlessWeb.Components.Container
      import PasswordlessWeb.Components.DataTable
      import PasswordlessWeb.Components.Dropdown
      import PasswordlessWeb.Components.Field
      import PasswordlessWeb.Components.Form
      import PasswordlessWeb.Components.Icon
      import PasswordlessWeb.Components.Input
      import PasswordlessWeb.Components.Link
      import PasswordlessWeb.Components.Loading
      import PasswordlessWeb.Components.Logo
      import PasswordlessWeb.Components.Modal
      import PasswordlessWeb.Components.PageComponents
      import PasswordlessWeb.Components.Pagination
      import PasswordlessWeb.Components.Progress
      import PasswordlessWeb.Components.PublicLayout
      import PasswordlessWeb.Components.Rating
      import PasswordlessWeb.Components.RouteTree
      import PasswordlessWeb.Components.SidebarLayout
      import PasswordlessWeb.Components.SignInButton
      import PasswordlessWeb.Components.SlideOver
      import PasswordlessWeb.Components.SocialButton
      import PasswordlessWeb.Components.StackedLayout
      import PasswordlessWeb.Components.Table
      import PasswordlessWeb.Components.Tabs
      import PasswordlessWeb.Components.ThemeSwitch
      import PasswordlessWeb.Components.Typography
      import PasswordlessWeb.Components.UserTopbarMenu
      import PasswordlessWeb.DashboardComponents
      import PasswordlessWeb.FileUploadComponents
    end
  end
end

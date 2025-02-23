defmodule PasswordlessWeb.Menus do
  @moduledoc """
  Describe all of your navigation menus in here. This keeps you from having to define them in a layout template
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org

  # Public menu (marketing related pages)
  def public_menu_items,
    do: [
      %{label: gettext("Product"), path: ~p"/product"},
      %{
        path: "/",
        label: gettext("Developers"),
        menu_items: [
          %{icon: "remix-news-line", label: gettext("Blog"), path: ~p"/blog"},
          %{icon: "remix-hand", label: gettext("Demo"), path: ~p"/book-demo"},
          %{icon: "remix-book-open-line", label: gettext("Documentation"), path: ~p"/docs"}
        ]
      },
      %{label: gettext("Pricing"), path: ~p"/pricing"},
      %{label: gettext("Demo"), path: ~p"/book-demo"}
    ]

  def public_mobile_menu_items(%User{}),
    do: [
      %{label: gettext("Product"), path: ~p"/product"},
      %{label: gettext("Pricing"), path: ~p"/pricing"},
      %{label: gettext("Demo"), path: ~p"/book-demo"},
      %{label: gettext("Open App"), path: ~p"/app/home"},
      %{label: gettext("Contact"), path: ~p"/contact"}
    ]

  def public_mobile_menu_items(_),
    do: [
      %{label: gettext("Product"), path: ~p"/product"},
      %{label: gettext("Pricing"), path: ~p"/pricing"},
      %{label: gettext("Demo"), path: ~p"/book-demo"},
      %{label: gettext("Sign In"), path: ~p"/auth/sign-in"},
      %{label: gettext("Contact"), path: ~p"/contact"}
    ]

  def main_menu_items(:app, %User{} = current_user),
    do: build_menu([:home, :users, :methods, :embed, :billing, :settings], current_user)

  def main_menu_items(:knowledge, %User{} = current_user), do: build_menu([:blog, :guides, :docs], current_user)

  def main_menu_items(:admin, %User{} = current_user),
    do:
      build_menu(
        [
          :user_admin,
          :token_admin,
          :credentials_admin,
          :membership_admin,
          :org_admin,
          :activity_admin,
          :live_dashboard,
          :oban_web
        ],
        current_user
      )

  def main_menu_items(:dev, %User{} = current_user),
    do:
      if(Passwordless.config(:env) == :dev,
        do: build_menu([:dev_routes, :dev_email_templates, :dev_sent_emails], current_user)
      )

  def main_menu_items(_section, _user), do: []

  def user_menu_items(%User{current_org: %Org{}} = current_user),
    do: build_menu([:members, :edit_projects, :edit_org, :sign_out], current_user)

  def user_menu_items(_user), do: []

  def section_menu_items(%User{} = current_user) do
    sections =
      [:app, :knowledge]
      |> append_if(:admin, User.is_admin?(current_user))
      |> append_if(:dev, Passwordless.config(:env) == :dev)

    build_menu(sections, current_user)
  end

  def section_menu_items(_user), do: []

  def footer_menu_items,
    do: [
      %{label: gettext("Home"), path: ~p"/"},
      %{label: gettext("Pricing"), path: ~p"/pricing"},
      %{label: gettext("Demo"), path: ~p"/book-demo"},
      %{label: gettext("Docs"), path: ~p"/docs"}
    ]

  def build_menu(menu_items, current_user \\ nil) do
    menu_items
    |> Enum.map(fn menu_item ->
      cond do
        menu_item == :separator ->
          %{separator: true}

        is_atom(menu_item) ->
          get_link(menu_item, current_user)

        is_list(menu_item) ->
          %{
            menu_items: Enum.map(menu_item, &get_link(&1, current_user))
          }

        is_map(menu_item) ->
          case menu_item do
            %{title: _title} = menu_item ->
              Map.put(menu_item, :menu_items, build_menu(menu_item.items, current_user))

            menu_item ->
              Map.merge(
                get_link(menu_item.name, current_user),
                menu_item
              )
          end
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def translate_item(item, current_user) when is_atom(item) and not is_nil(item) do
    case get_link(item, current_user) do
      %{label: label} -> label
      _ -> ""
    end
  end

  def get_link(name, current_user \\ nil)

  def get_link(:sign_out = name, user) do
    if user.current_impersonator do
      %{
        name: name,
        label: gettext("Exit Impersonation"),
        path: ~p"/admin/impersonate",
        icon: "remix-close-large-fill",
        method: :delete,
        color: :red
      }
    else
      %{
        name: name,
        label: gettext("Sign Out"),
        path: ~p"/auth/sign-out",
        icon: "remix-logout-box-line",
        method: :delete,
        color: :red
      }
    end
  end

  def get_link(:edit_profile = name, _user) do
    %{
      name: name,
      label: gettext("Profile"),
      path: ~p"/app/settings",
      icon: "remix-at-line"
    }
  end

  def get_link(:edit_email = name, _user) do
    %{
      name: name,
      label: gettext("Login Email"),
      path: ~p"/app/edit-email",
      icon: "remix-at-line"
    }
  end

  def get_link(:edit_password = name, _user) do
    %{
      name: name,
      label: gettext("Password"),
      path: ~p"/app/password",
      icon: "remix-key-line"
    }
  end

  def get_link(:org_invitations = name, _user) do
    %{
      name: name,
      label: gettext("Invitations"),
      path: ~p"/app/invitations",
      icon: "remix-mail-line"
    }
  end

  def get_link(:edit_totp = name, _user) do
    %{
      name: name,
      label: gettext("Security"),
      path: ~p"/app/security",
      icon: "remix-lock-line"
    }
  end

  def get_link(:users = name, %User{} = user) do
    %{
      name: name,
      label: gettext("Users"),
      path: ~p"/app/users",
      icon: "remix-robot-3-line",
      link_type: "live_patch"
    }
  end

  def get_link(:home = name, %User{} = _user) do
    %{
      name: name,
      label: gettext("Home"),
      path: ~p"/app/home",
      icon: "remix-ruler-line",
      link_type: "live_patch"
    }
  end

  def get_link(:methods = name, %User{} = _user) do
    %{
      name: name,
      label: gettext("Methods"),
      path: ~p"/app/methods",
      icon: "remix-database-2-line",
      link_type: "live_patch"
    }
  end

  def get_link(:reports = name, %User{} = _user) do
    %{
      name: name,
      label: gettext("Reports"),
      path: ~p"/app/reports",
      icon: "remix-database-2-line",
      link_type: "live_patch"
    }
  end

  def get_link(:settings = name, _user) do
    %{
      name: name,
      label: gettext("Settings"),
      path: ~p"/app/settings",
      icon: "remix-settings-2-line",
      link_type: "live_redirect"
    }
  end

  def get_link(:app = name, _user) do
    %{
      name: name,
      label: gettext("Home"),
      path: ~p"/app/home",
      icon: "custom-dashboard"
    }
  end

  def get_link(:knowledge = name, _user) do
    %{
      name: name,
      label: gettext("Knowledge Base"),
      path: ~p"/app/docs",
      icon: "custom-knowledge"
    }
  end

  def get_link(:admin = name, _user) do
    %{
      name: name,
      label: gettext("Admin"),
      path: ~p"/admin/users",
      icon: "custom-integration"
    }
  end

  def get_link(:dev = name, _user) do
    %{
      name: name,
      label: gettext("Dev"),
      path: ~p"/dev",
      icon: "custom-more-dots"
    }
  end

  def get_link(:org_admin = name, _user) do
    %{
      name: name,
      label: gettext("Organizations"),
      path: ~p"/admin/orgs",
      icon: "remix-building-line",
      link_type: "live_patch"
    }
  end

  def get_link(:user_admin = name, _user) do
    %{
      name: name,
      label: gettext("Users"),
      path: ~p"/admin/users",
      icon: "remix-user-line",
      link_type: "live_patch"
    }
  end

  def get_link(:token_admin = name, _user) do
    %{
      name: name,
      label: gettext("Tokens"),
      path: ~p"/admin/tokens",
      icon: "remix-lock-line",
      link_type: "live_patch"
    }
  end

  def get_link(:membership_admin = name, _user) do
    %{
      name: name,
      label: gettext("Memberships"),
      path: ~p"/admin/memberships",
      icon: "remix-organization-chart",
      link_type: "live_patch"
    }
  end

  def get_link(:credentials_admin = name, _user) do
    %{
      name: name,
      label: gettext("Credentials"),
      path: ~p"/admin/credentials",
      icon: "remix-id-card-line",
      link_type: "live_patch"
    }
  end

  def get_link(:passwordless_admin = name, _user) do
    %{
      name: name,
      label: gettext("Checks"),
      path: ~p"/admin/checks",
      icon: "remix-radar-line",
      link_type: "live_patch"
    }
  end

  def get_link(:activity_admin = name, _user) do
    %{
      name: name,
      label: gettext("Activity"),
      path: ~p"/admin/activity",
      icon: "remix-file-paper-2-line",
      link_type: "live_patch"
    }
  end

  def get_link(:live_dashboard = name, _user) do
    %{
      name: name,
      label: gettext("Live Dashboard"),
      path: ~p"/admin/live",
      icon: "remix-dashboard-2-line",
      link_type: "live_patch"
    }
  end

  def get_link(:oban_web = name, _user) do
    %{
      name: name,
      label: gettext("Oban Web"),
      path: ~p"/admin/oban",
      icon: "remix-hard-drive-3-line",
      link_type: "live_patch"
    }
  end

  def get_link(:blog = name, _user) do
    %{
      name: name,
      label: gettext("Blog"),
      path: ~p"/app/blog",
      icon: "remix-news-line"
    }
  end

  def get_link(:docs = name, _user) do
    %{
      name: name,
      label: gettext("Documentation"),
      path: ~p"/app/docs",
      icon: "remix-book-open-line"
    }
  end

  def get_link(:guides = name, _user) do
    %{
      name: name,
      label: gettext("Guides"),
      path: ~p"/app/guides",
      icon: "remix-graduation-cap-line",
      link_type: "live_patch"
    }
  end

  def get_link(:knowledge_base = name, _user) do
    %{
      name: name,
      label: gettext("Knowledge Base"),
      path: ~p"/app/docs",
      icon: "custom-knowledge"
    }
  end

  def get_link(:edit_projects = name, _user) do
    %{
      name: name,
      label: gettext("Projects"),
      path: ~p"/app/projects",
      icon: "remix-instance-line",
      link_type: "live_patch"
    }
  end

  def get_link(:edit_org = name, _user) do
    %{
      name: name,
      label: gettext("Organization"),
      path: ~p"/app/organization",
      icon: "remix-building-line",
      link_type: "live_patch"
    }
  end

  def get_link(:members = name, _user) do
    %{
      name: name,
      label: gettext("Team"),
      path: ~p"/app/members",
      icon: "remix-group-line",
      link_type: "live_patch"
    }
  end

  def get_link(:auth_tokens = name, _user) do
    %{
      name: name,
      label: gettext("Auth tokens"),
      path: ~p"/app/auth-tokens",
      icon: "remix-code-s-slash-line",
      link_type: "live_redirect"
    }
  end

  def get_link(:billing = name, _user) do
    %{
      name: name,
      label: gettext("Billing"),
      path: ~p"/app/billing",
      icon: "remix-bill-line",
      link_type: "live_patch"
    }
  end

  def get_link(:embed = name, _user) do
    %{
      name: name,
      label: gettext("Embed & API"),
      path: ~p"/app/embed",
      icon: "remix-plug-line",
      link_type: "live_patch"
    }
  end

  def get_link(:dev_routes = name, _current_user) do
    if Passwordless.config(:env) == :dev do
      %{
        name: name,
        label: gettext("App Routes"),
        path: "/dev",
        icon: "remix-router-line",
        link_type: "live_patch"
      }
    end
  end

  def get_link(:dev_email_templates = name, _current_user) do
    if Passwordless.config(:env) == :dev do
      %{
        name: name,
        label: gettext("Email Templates"),
        path: "/dev/emails",
        icon: "remix-mail-line",
        link_type: "live_patch"
      }
    end
  end

  def get_link(:dev_sent_emails = name, _current_user) do
    if Passwordless.config(:env) == :dev do
      %{
        name: name,
        label: gettext("Sent Emails"),
        path: "/dev/emails/sent",
        icon: "remix-mail-send-line",
        link_type: "live_patch"
      }
    end
  end

  # Private

  defp append_if(list, _value, false), do: list
  defp append_if(list, value, true), do: list ++ List.wrap(value)
end

defmodule PasswordlessWeb.Menus do
  @moduledoc """
  Describe all of your navigation menus in here. This keeps you from having to define them in a layout template
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Accounts.User
  alias Passwordless.Organizations.Org

  # Public menu (marketing related pages)
  def public_menu_items, do: []

  def public_mobile_menu_items(%User{}), do: []

  def public_mobile_menu_items(_), do: []

  def main_menu_items(:app, %User{} = current_user),
    do: build_menu([:home, :users, :methods, :embed, :settings], current_user)

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
    do: if(Passwordless.config(:env) == :dev, do: build_menu([:dev_email_templates, :dev_sent_emails], current_user))

  def main_menu_items(_section, _user), do: []

  def user_menu_items(%User{current_org: %Org{}} = current_user),
    do: build_menu([:app, :team, :billing, :sign_out], current_user)

  def user_menu_items(_user), do: []

  def section_menu_items(%User{} = current_user) do
    sections =
      [:app, :knowledge]
      |> append_if(:admin, User.is_admin?(current_user))
      |> append_if(:dev, Passwordless.config(:env) == :dev)

    build_menu(sections, current_user)
  end

  def section_menu_items(_user), do: []

  def footer_menu_items, do: [%{label: gettext("Home"), path: ~p"/"}, %{label: gettext("Pricing"), path: ~p"/pricing"}]

  def build_menu(menu_items, current_user \\ nil) do
    menu_items
    |> Enum.map(fn menu_item ->
      cond do
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
      path: ~p"/app/profile",
      icon: "remix-at-line",
      link_type: "live_patch"
    }
  end

  def get_link(:edit_password = name, _user) do
    %{
      name: name,
      label: gettext("Password"),
      path: ~p"/app/password",
      icon: "remix-key-line",
      link_type: "live_patch"
    }
  end

  def get_link(:org_invitations = name, _user) do
    %{
      name: name,
      label: gettext("Invitations"),
      path: ~p"/app/invitations",
      icon: "remix-mail-line",
      link_type: "live_patch"
    }
  end

  def get_link(:edit_totp = name, _user) do
    %{
      name: name,
      label: gettext("Security"),
      path: ~p"/app/security",
      icon: "remix-lock-line",
      link_type: "live_patch"
    }
  end

  def get_link(:users = name, _user) do
    %{
      name: name,
      label: gettext("Users"),
      path: ~p"/app/users",
      icon: "remix-user-line",
      link_type: "live_patch"
    }
  end

  def get_link(:home = name, _user) do
    %{
      name: name,
      label: gettext("Home"),
      path: ~p"/app/home",
      icon: "remix-home-line",
      link_type: "live_patch"
    }
  end

  def get_link(:methods = name, _user) do
    %{
      name: name,
      label: gettext("Methods"),
      path: ~p"/app/methods/email",
      icon: "remix-shield-user-line",
      link_type: "live_patch"
    }
  end

  def get_link(:reports = name, _user) do
    %{
      name: name,
      label: gettext("Reports"),
      path: ~p"/app/reports",
      icon: "remix-pie-chart-line",
      link_type: "live_patch"
    }
  end

  def get_link(:settings = name, _user) do
    %{
      name: name,
      label: gettext("Settings"),
      path: ~p"/app/app",
      icon: "remix-settings-2-line",
      link_type: "live_patch"
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
      path: ~p"/dev/emails",
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

  def get_link(:app = name, _user) do
    %{
      name: name,
      label: gettext("App"),
      path: ~p"/app/app",
      icon: "remix-instance-line",
      link_type: "live_patch"
    }
  end

  def get_link(:organization = name, _user) do
    %{
      name: name,
      label: gettext("Organization"),
      path: ~p"/app/organization",
      icon: "remix-building-line",
      link_type: "live_patch"
    }
  end

  def get_link(:team = name, _user) do
    %{
      name: name,
      label: gettext("Team"),
      path: ~p"/app/team",
      icon: "remix-group-line",
      link_type: "live_patch"
    }
  end

  def get_link(:domain = name, _user) do
    %{
      name: name,
      label: gettext("Domain"),
      path: ~p"/app/domain",
      icon: "remix-cloud-line",
      link_type: "live_patch"
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
      path: ~p"/app/embed/secrets",
      icon: "remix-terminal-box-line",
      link_type: "live_patch"
    }
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

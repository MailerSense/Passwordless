defmodule PasswordlessWeb.Helpers do
  @moduledoc """
  A set of helpers used in web related views and templates. These functions can be called anywhere in a heex template.
  """

  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Accounts.User
  alias Passwordless.Action
  alias Passwordless.Activity.Log
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.EmailTemplate
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  def actor_name(%Actor{} = actor), do: actor.name
  def actor_name(_actor), do: nil

  def actor_state_badge(%Actor{} = actor),
    do:
      {Phoenix.Naming.humanize(actor.state),
       case actor.state do
         :active -> "success"
         :locked -> "danger"
       end}

  def action_state_badge(%Action{} = action),
    do:
      {Phoenix.Naming.humanize(action.state),
       case action.state do
         :allow -> "success"
         :timeout -> "warning"
         :block -> "danger"
         _ -> "gray"
       end}

  def action_state_badge(_actor), do: {nil, "gray"}

  def embed_menu_items do
    [
      %{
        name: :install,
        label: "Installation",
        icon: "remix-install-line",
        path: ~p"/embed/install",
        link_type: "live_patch"
      },
      %{
        name: :api,
        label: "Headless API",
        icon: "remix-code-s-slash-line",
        path: ~p"/embed/api",
        link_type: "live_patch"
      },
      %{
        name: :ui,
        label: "UI Components",
        icon: "remix-window-line",
        path: ~p"/embed/ui",
        link_type: "live_patch"
      }
    ]
  end

  def authenticator_menu_items do
    [
      %{
        name: :email,
        label: "Email",
        icon: "remix-mail-open-line",
        path: ~p"/authenticators/email",
        link_type: "live_patch"
      },
      %{
        name: :sms,
        label: "SMS",
        icon: "remix-message-2-line",
        path: ~p"/authenticators/sms",
        link_type: "live_patch"
      },
      %{
        name: :whatsapp,
        label: "WhatsApp",
        icon: "remix-whatsapp-line",
        path: ~p"/authenticators/whatsapp",
        link_type: "live_patch"
      },
      %{
        name: :magic_link,
        label: "Magic link",
        icon: "remix-link",
        path: ~p"/authenticators/magic-link",
        link_type: "live_patch"
      },
      %{
        name: :totp,
        label: "Time-based OTP",
        icon: "remix-qr-code-line",
        path: ~p"/authenticators/totp",
        link_type: "live_patch"
      },
      %{
        name: :security_key,
        label: "Security key",
        icon: "remix-usb-line",
        path: ~p"/authenticators/security-key",
        link_type: "live_patch"
      },
      %{
        name: :passkey,
        label: "Passkey",
        icon: "remix-fingerprint-line",
        path: ~p"/authenticators/passkey",
        link_type: "live_patch"
      },
      %{
        name: :recovery_codes,
        label: "Recovery codes",
        icon: "remix-file-list-line",
        path: ~p"/authenticators/recovery-codes",
        link_type: "live_patch"
      }
    ]
  end

  def flow_details(%Action{challenge: %Challenge{type: type}}) do
    Keyword.get(
      [
        email_otp: %{label: gettext("Email OTP"), icon: "remix-mail-open-line"},
        sms_otp: %{label: gettext("SMS OTP"), icon: "remix-message-line"},
        whatsapp_otp: %{label: gettext("WhatsApp OTP"), icon: "remix-whatsapp-line"},
        magic_link: %{label: gettext("Magic link"), icon: "remix-link"},
        totp: %{label: gettext("Time-based OTP"), icon: "remix-qr-code-line"},
        security_key: %{label: gettext("Security key"), icon: "remix-usb-line"},
        passkey: %{label: gettext("Passkey"), icon: "remix-fingerprint-line"},
        password: %{label: gettext("Password"), icon: "remix-key-line"},
        recovery_codes: %{label: gettext("Recovery codes"), icon: "remix-file-list-line"}
      ],
      type
    )
  end

  def flow_details(%Action{}) do
    %{label: gettext("None"), icon: "remix-fingerprint-line"}
  end

  def actor_menu_items(%Actor{} = actor) do
    [
      %{
        name: :details,
        label: "Details",
        path: ~p"/users/#{actor}/edit",
        link_type: "live_patch"
      },
      %{
        name: :activity,
        label: "Authenticators",
        path: ~p"/users/#{actor}/activity",
        link_type: "live_patch"
      }
    ]
  end

  def email_menu_items(%EmailTemplate{} = email_template, language \\ :en) do
    [
      %{
        name: :edit,
        label: gettext("Email"),
        path: ~p"/emails/#{email_template}/#{language}/edit",
        link_type: "live_patch"
      },
      %{
        name: :code,
        label: gettext("Code"),
        path: ~p"/emails/#{email_template}/#{language}/code",
        link_type: "live_patch"
      },
      %{
        name: :files,
        label: gettext("Files"),
        path: ~p"/emails/#{email_template}/#{language}/files",
        link_type: "live_patch"
      }
    ]
  end

  def org_menu_items(%User{} = user) do
    user
    |> Organizations.list_orgs()
    |> Enum.sort_by(& &1.name, :desc)
    |> Enum.reject(fn %Org{id: id} ->
      case user.current_org do
        %Org{id: ^id} -> true
        _ -> false
      end
    end)
  end

  def org_menu_items(_user), do: []

  def app_menu_items(%User{current_org: %Org{} = org} = user) do
    org
    |> Organizations.list_apps()
    |> Enum.sort_by(& &1.name, :desc)
    |> Enum.reject(fn %App{id: id} ->
      case user.current_app do
        %App{id: ^id} -> true
        _ -> false
      end
    end)
  end

  def app_menu_items(_user), do: []

  def user_menu_items(user) do
    PasswordlessWeb.Menus.user_menu_items(user)
  end

  def main_menu_items(section, user) do
    PasswordlessWeb.Menus.main_menu_items(section, user)
  end

  def section_menu_items(user) do
    PasswordlessWeb.Menus.section_menu_items(user)
  end

  def public_menu_items do
    PasswordlessWeb.Menus.public_menu_items()
  end

  def public_mobile_menu_items(user) do
    PasswordlessWeb.Menus.public_mobile_menu_items(user)
  end

  def footer_menu_items do
    PasswordlessWeb.Menus.footer_menu_items()
  end

  def get_menu_item(name, user) do
    PasswordlessWeb.Menus.get_link(name, user)
  end

  def home_path(nil), do: "/"
  def home_path(%User{}), do: ~p"/home"

  def user_name(nil), do: nil
  def user_name(%User{} = user), do: user.name

  def user_first_name(nil), do: nil
  def user_first_name(%User{} = user), do: user.name |> String.split(" ") |> hd()

  def user_email(nil), do: nil
  def user_email(%User{} = user), do: user.email

  def user_state(nil), do: nil
  def user_state(%User{} = user), do: user.state

  def user_org_name(%User{current_org: %Org{name: name}}) when is_binary(name), do: Util.truncate(name)

  def user_org_name(_), do: nil

  def user_app_name(%User{current_app: %App{name: name}}) when is_binary(name), do: Util.truncate(name)

  def user_app_name(_), do: nil

  def user_impersonated?(%User{current_impersonator: %User{}}), do: true
  def user_impersonated?(_), do: false

  def user_impersonator_name(%User{current_impersonator: %User{} = user}), do: user_name(user)
  def user_impersonator_name(_), do: nil

  def format_date_time(date, format \\ "%d %B %Y, %H:%M")
  def format_date_time(nil, _format), do: ""
  def format_date_time(date, format), do: Timex.format!(date, format, :strftime)

  def format_date(date, format \\ "%-d %B %Y")
  def format_date(nil, _format), do: ""
  def format_date(date, format), do: Timex.format!(date, format, :strftime)

  def format_month_range(%Date{} = month) do
    start_date = Timex.beginning_of_month(month)
    end_date = Timex.end_of_month(month)

    "#{format_date(start_date, "%-d %b")} - #{format_date(end_date, "%-d %b %Y")}"
  end

  def current_month?(%Date{} = month) do
    span_start = Timex.beginning_of_month(month)
    span_end = Timex.end_of_month(month)

    interval =
      Timex.Interval.new(
        from: span_start,
        until: span_end,
        left_open: false,
        right_open: false
      )

    Timex.today() in interval
  end

  def user_added(%Membership{inserted_at: %DateTime{} = inserted_at}), do: format_date_time(inserted_at)

  def user_added(%Membership{}), do: ""

  def admin?(%User{} = user), do: User.admin?(user)
  def admin?(_user), do: false

  @common_colors ~w(blue indigo purple fuchsia pink cyan teal sky)

  def translate_action(action) do
    Phoenix.Naming.humanize(action)
  end

  def log_source(nil), do: gettext("Dashboard")
  def log_source("api"), do: gettext("API")
  def log_source(source) when is_atom(source), do: Phoenix.Naming.humanize(Atom.to_string(source))
  def log_source(source) when is_binary(source), do: Phoenix.Naming.humanize(source)
  def log_source(_), do: "-"

  def log_source_badge(nil = source), do: {log_source(source), "blue"}

  def log_source_badge(source),
    do: {log_source(source), Enum.at(@common_colors, :erlang.phash2(source, length(@common_colors)))}

  def log_action_badge(%Log{action: action}),
    do: {translate_action(action), Enum.at(@common_colors, :erlang.phash2(action, length(@common_colors)))}

  def random_color(term), do: Enum.at(@common_colors, :erlang.phash2(term, length(@common_colors)))

  @icon_mapping %{
    "create_auth_token" => "🔑",
    "update_auth_token" => "🔑",
    "revoke_auth_token" => "🔑",
    "join_list" => "📝",
    "leave_list" => "📝",
    "delete" => "❌",
    "delete_invitation" => "❌",
    "subscribe" => "✅",
    "unsubscribe" => "❌",
    "not_subscribe" => "🤷",
    "subscribe_to_topic" => "✅",
    "unsubscribe_from_topic" => "❌"
  }
  @icon_fallback_mapping %{
    "user" => "👤",
    "org" => "🏢",
    "identity" => "📮",
    "message" => "📩",
    "contact" => "🧑",
    "list" => "📝"
  }

  @resource_colors %{
    "user" => "primary",
    "org" => "indigo",
    "identity" => "purple",
    "message" => "purple"
  }

  def action_icon(action) do
    case String.split(action, ".", parts: 2) do
      [domain, action] ->
        Map.get(@icon_mapping, action, Map.get(@icon_fallback_mapping, domain, "👋"))

      _ ->
        "👋"
    end
  end

  def action_color(action) do
    case String.split(action, ".", parts: 2) do
      [domain, action] when is_binary(domain) ->
        if String.contains?(String.downcase(action), ["delete", "revoke", "cancel"]) do
          "danger"
        else
          Map.get(@resource_colors, domain, "primary")
        end

      _ ->
        "primary"
    end
  end

  def auth_token_scopes(%AuthToken{scopes: [_ | _] = scopes}) when length(scopes) > 2,
    do:
      scopes
      |> Enum.sort()
      |> Enum.take(1)
      |> Enum.map_join(", ", &Atom.to_string/1)
      |> String.capitalize()
      |> Kernel.<>(", #{Enum.count(scopes) - 1} more")

  def auth_token_scopes(%AuthToken{scopes: [_ | _] = scopes}),
    do: scopes |> Enum.sort() |> Enum.map_join(", ", &Atom.to_string/1) |> String.capitalize()

  def auth_token_scopes(_), do: "-"

  # Autofocuses the input
  # <input {alpine_autofocus()} />
  def alpine_autofocus do
    %{
      "x-data": "",
      "x-init": "$nextTick(() => { $el.focus() });"
    }
  end

  ## SEO

  def assign_page_title(socket, title) when is_binary(title) do
    title_suffix = PasswordlessWeb.SEO.site_config(nil).title_suffix
    seo = socket.assigns[:seo] || %{}
    seo = Map.put(seo, :title, title <> title_suffix)

    Phoenix.Component.assign(socket, page_title: title, seo: seo)
  end

  def assign_page_title(socket, _title), do: socket

  def assign_page_description(socket, description) when is_binary(description) do
    seo = socket.assigns[:seo] || %{}
    seo = Map.put(seo, :description, description)

    Phoenix.Component.assign(socket, seo: seo)
  end

  def assign_page_description(socket, _description), do: socket
end

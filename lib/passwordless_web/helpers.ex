defmodule PasswordlessWeb.Helpers do
  @moduledoc """
  A set of helpers used in web related views and templates. These functions can be called anywhere in a heex template.
  """

  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Accounts.User
  alias Passwordless.Action
  alias Passwordless.ActionTemplate
  alias Passwordless.Activity.Log
  alias Passwordless.App
  alias Passwordless.AuthToken
  alias Passwordless.Challenge
  alias Passwordless.EmailTemplate
  alias Passwordless.Event
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  def action_state_info(%Action{} = action),
    do:
      {case action.state do
         :allow -> "Allow to"
         :timeout -> "Timeout when trying to"
         :block -> "Block attempt to"
         _ -> "Attempting to"
       end,
       case action.state do
         :allow -> "success"
         :timeout -> "warning"
         :block -> "danger"
         _ -> "info"
       end}

  def action_state_info(_user), do: {nil, "info"}

  def action_state_badge(%Action{} = action),
    do:
      {case action.state do
         :allow -> "Allow"
         :timeout -> "Timeout"
         :block -> "Block"
         _ -> "Attempt"
       end,
       case action.state do
         :allow -> "success"
         :timeout -> "warning"
         :block -> "danger"
         _ -> "info"
       end}

  def action_state_badge(_user), do: {nil, "info"}

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
        name: :ui,
        label: "Components",
        icon: "remix-cursor-line",
        path: ~p"/embed/ui",
        link_type: "live_patch"
      },
      %{
        name: :api,
        label: "Backend API",
        icon: "remix-code-s-slash-line",
        path: ~p"/embed/api",
        link_type: "live_patch"
      }
    ]
  end

  def action_menu_items(%ActionTemplate{} = action_template) do
    [
      %{
        name: :edit,
        label: "Rules",
        icon: "remix-checkbox-line",
        path: ~p"/actions/#{action_template}/edit",
        link_type: "live_patch"
      },
      %{
        name: :embed,
        label: "Embed",
        icon: "remix-code-s-slash-line",
        path: ~p"/actions/#{action_template}/embed",
        link_type: "live_patch"
      },
      %{
        name: :activity,
        label: "Activity",
        icon: "remix-line-chart-line",
        path: ~p"/actions/#{action_template}/activity",
        link_type: "live_patch"
      }
    ]
  end

  def authenticator_menu_items do
    [
      %{
        name: :email_otp,
        label: "Email OTP",
        icon: "remix-mail-open-line",
        path: ~p"/authenticators/email-otp",
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
        name: :passkey,
        label: "Passkey",
        icon: "remix-fingerprint-line",
        path: ~p"/authenticators/passkey",
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
        name: :totp,
        label: "Time-based OTP",
        icon: "remix-qr-code-line",
        path: ~p"/authenticators/totp",
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

  def verbalize_action(
        %Action{challenge: %Challenge{} = challenge, template: %ActionTemplate{name: name}, events: events} = action
      ) do
    name = Recase.to_sentence(name)

    challenge_name =
      case challenge.kind do
        :email_otp -> gettext("email OTP")
        :magic_link -> gettext("magic link")
        :password -> gettext("password")
        _ -> gettext("Unknown Challenge")
      end

    label =
      case action.state do
        :allow -> gettext("\"%{action}\" allowed", action: name, challenge: challenge_name)
        :timeout -> gettext("\"%{action}\" timed out", action: name, challenge: challenge_name)
        :block -> gettext("\"%{action}\" blocked", action: name, challenge: challenge_name)
        _ -> gettext("\"%{action}\" challenged", action: name, challenge: challenge_name)
      end

    color =
      case action.state do
        :allow -> "success"
        :timeout -> "warning"
        :block -> "danger"
        _ -> "info"
      end

    events =
      Enum.map(events, fn %Event{event: event, inserted_at: inserted_at} = event_struct ->
        name =
          case event do
            "send_otp" -> gettext("Requested a %{challenge}", challenge: challenge_name)
            "send_link" -> gettext("Requested a %{challenge}", challenge: challenge_name)
            "verify_otp" -> gettext("Presented valid OTP")
            "verify_link" -> gettext("Clicked the link")
            "verify_password" -> gettext("Presented valid password")
            _ -> gettext("Unknown event")
          end

        name =
          if not is_nil(event_struct.country) and not is_nil(event_struct.city) do
            gettext("%{time} - %{event} from %{city}, %{country}",
              time: format_hour(inserted_at),
              event: name,
              city: event_struct.city,
              country: event_struct.country
            )
          else
            gettext("%{time} - %{event}", time: format_hour(inserted_at), event: name)
          end

        %{
          name: name
        }
      end)

    %{
      name: label,
      color: color,
      events: events
    }
  end

  def flow_details(%Action{challenge: %Challenge{kind: kind}}) do
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
      kind
    )
  end

  def flow_details(%Action{}) do
    %{label: gettext("None"), icon: "remix-fingerprint-line"}
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

  def format_hour(date, format \\ "%H:%M")
  def format_hour(nil, _format), do: ""
  def format_hour(date, format), do: Timex.format!(date, format, :strftime)

  def format_date(date, format \\ "%-d %B %Y")
  def format_date(nil, _format), do: ""
  def format_date(date, format), do: Timex.format!(date, format, :strftime)

  def format_relative(date, format \\ "%d %B %Y, %H:%M") do
    one_day_ago = Timex.shift(DateTime.utc_now(), days: -1)

    if Timex.before?(date, one_day_ago),
      do: format_date_time(date, format),
      else: Timex.from_now(date)
  end

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

  @common_colors ~w(
    indigo
    purple
    fuchsia
    pink
    rose
    cyan
  )

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

  def auth_token_permissions(%AuthToken{permissions: [_ | _] = permissions}) when length(permissions) > 2,
    do:
      permissions
      |> Enum.sort()
      |> Enum.take(1)
      |> Enum.map_join(", ", &Atom.to_string/1)
      |> String.capitalize()
      |> Kernel.<>(", #{Enum.count(permissions) - 1} more")

  def auth_token_permissions(%AuthToken{permissions: [_ | _] = permissions}),
    do: permissions |> Enum.sort() |> Enum.map_join(", ", &Atom.to_string/1) |> String.capitalize()

  def auth_token_permissions(_), do: "-"

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

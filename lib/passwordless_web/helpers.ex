defmodule PasswordlessWeb.Helpers do
  @moduledoc """
  A set of helpers used in web related views and templates. These functions can be called anywhere in a heex template.
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Action
  alias Passwordless.Activity.Log
  alias Passwordless.Actor
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org
  alias Passwordless.Project

  def actor_state_badge(nil), do: {nil, "gray"}

  def actor_state_badge(%Actor{} = actor),
    do:
      {Phoenix.Naming.humanize(actor.state),
       case actor.state do
         :healthy -> "success"
         :warning -> "warning"
         :locked -> "danger"
       end}

  def action_state_badge(nil), do: {nil, "gray"}

  def action_state_badge(%Action{} = action),
    do:
      {Phoenix.Naming.humanize(action.outcome),
       case action.outcome do
         :success -> "success"
         :timeout -> "warning"
         :fail -> "danger"
         _ -> "gray"
       end}

  def method_menu_items do
    [
      %{
        name: :magic_link,
        label: "Magic Link",
        icon: "remix-magic-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      },
      %{
        name: :sms_otp,
        label: "SMS",
        icon: "remix-message-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      },
      %{
        name: :email_otp,
        label: "Email",
        icon: "remix-mail-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      },
      %{
        name: :authenticator_app,
        label: "Authenticator",
        icon: "remix-shield-user-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      },
      %{
        name: :whatsapp_otp,
        label: "WhatsApp",
        icon: "remix-whatsapp-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      },
      %{
        name: :passkey,
        label: "Passkey",
        icon: "remix-pass-valid-line",
        path: ~p"/app/checks",
        link_type: "live_patch"
      }
    ]
  end

  def org_menu_items(%User{all_orgs: [_ | _] = orgs} = user) do
    orgs
    |> Enum.sort_by(& &1.name, :desc)
    |> Enum.reject(fn %Org{id: id} ->
      case user.current_org do
        %Org{id: ^id} -> true
        _ -> false
      end
    end)
  end

  def org_menu_items(_user), do: []

  def project_menu_items(%User{current_org: %Org{} = org, all_projects: [_ | _] = projects} = user) do
    projects
    |> Enum.sort_by(& &1.name, :desc)
    |> Enum.reject(fn %Project{id: id} ->
      case user.current_project do
        %Project{id: ^id} -> true
        _ -> false
      end
    end)
  end

  def project_menu_items(_user), do: []

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
  def home_path(%User{}), do: ~p"/app/home"

  def user_name(nil), do: nil
  def user_name(%User{} = user), do: user.name

  def user_first_name(nil), do: nil
  def user_first_name(%User{} = user), do: user.name |> String.split(" ") |> hd()

  def user_email(nil), do: nil
  def user_email(%User{} = user), do: user.email

  def user_state(nil), do: nil
  def user_state(%User{} = user), do: user.state

  def user_2fa_enabled(nil), do: false
  def user_2fa_enabled(%User{} = user), do: Accounts.two_factor_auth_enabled?(user)

  def user_2fa_badge(nil), do: {nil, "danger"}

  def user_2fa_badge(%User{} = user),
    do:
      {if(Accounts.two_factor_auth_enabled?(user), do: gettext("2FA Enabled"), else: gettext("2FA Disabled")),
       if(Accounts.two_factor_auth_enabled?(user), do: "success", else: "danger")}

  def user_states, do: Enum.map(User.states(), &{String.capitalize(Atom.to_string(&1)), &1})

  def user_org_name(%User{current_org: %Org{name: name}}) when is_binary(name), do: name
  def user_org_name(_), do: nil

  def user_project_name(%User{current_project: %Project{name: name}}) when is_binary(name), do: name

  def user_project_name(_), do: gettext("No Project")

  def user_impersonated?(%User{current_impersonator: %User{}}), do: true
  def user_impersonated?(_), do: false

  def user_impersonator_name(%User{current_impersonator: %User{} = user}), do: user_name(user)
  def user_impersonator_name(_), do: nil

  def admin?(%User{}), do: false

  def format_date_time(date, format \\ "%b %d %H:%M")
  def format_date_time(nil, _format), do: ""
  def format_date_time(date, format), do: Timex.format!(date, format, :strftime)

  def format_date(date, format \\ "%-d %b %Y")
  def format_date(nil, _format), do: ""
  def format_date(date, format), do: Timex.format!(date, format, :strftime)

  def format_month_range(%Date{year: year, month: month} = date) do
    start_date = Timex.format!(Date.beginning_of_month(date), "{D}st")
    end_date = Timex.format!(Date.end_of_month(date), "{D}st")
    month = Timex.format!(date, "{Mshort}")
    "#{start_date} - #{end_date} #{month}"
  end

  def user_role(%Membership{role: role}) when is_atom(role), do: String.capitalize(Atom.to_string(role))

  def user_role(%Membership{}), do: "-"

  def user_added(%Membership{inserted_at: %DateTime{} = inserted_at}), do: format_date_time(inserted_at)

  def user_added(%Membership{}), do: ""

  def is_admin?(%User{} = user), do: User.is_admin?(user)
  def is_admin?(_user), do: false

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

  def random_color(term, colors \\ @common_colors), do: Enum.at(colors, :erlang.phash2(term, length(colors)))

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

  def status_page_visibilities,
    do: [
      public: {gettext("Anyone with link can view"), "primary"},
      private: {gettext("Password protected"), "purple"},
      hidden: {gettext("Not accessible"), "danger"}
    ]

  # Autofocuses the input
  # <input {alpine_autofocus()} />
  def alpine_autofocus do
    %{
      "x-data": "",
      "x-init": "$nextTick(() => { $el.focus() });"
    }
  end

  @doc """
  When you want to display code in a heex template, you can use this helper to escape it.
  """
  def code_block(code) do
    Phoenix.HTML.raw("""
    <pre>#{code}</pre>
    """)
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

  # Date

  def current_month_menu_item do
    date = DateTime.utc_now()
    "#{date.year}:#{date.month}"
  end

  def last_months_menu(limit \\ 2) do
    now = DateTime.utc_now()

    for_result =
      for i <- 0..limit do
        date = Timex.shift(now, months: -i)
        %{name: "#{date.year}:#{date.month}", label: Timex.format!(date, "%b %Y", :strftime)}
      end

    [%{name: "custom", label: "Custom"} | Enum.reverse(for_result)]
  end
end

defmodule PasswordlessWeb.UserAuth do
  @moduledoc """
  A set of plugs related to user authentication.
  This module is imported into the router and thus any function can be called there as a plug.
  """
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import Phoenix.Controller
  import Plug.Conn

  alias Passwordless.Accounts
  alias Passwordless.Accounts.Token
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  require Logger

  @doc """
  Logs the user in.
  """
  def log_in(conn, user, opts \\ [])

  def log_in(%Plug.Conn{} = conn, %User{} = user, opts) do
    via = Keyword.get(opts || [], :via, :password)
    conn = put_user_into_session(conn, user)

    Activity.log_async(:user, :"user.sign_in", %{user: user, via: via})

    if Accounts.two_factor_auth_enabled?(user) do
      conn
      |> put_session(:user_totp_pending, true)
      |> put_flash(:info, nil)
      |> redirect(to: ~p"/app/user/totp")
    else
      redirect_user_after_login(conn, user)
    end
  end

  def log_in(%Plug.Conn{} = conn, _user, _opts) do
    conn =
      put_flash(
        conn,
        :error,
        gettext("There is a problem with your account. Please contact support.")
      )

    redirect(conn, to: ~p"/auth/sign-in")
  end

  @doc """
  Generates a session token for the user and puts it in the session.
  """
  def put_user_into_session(%Plug.Conn{} = conn, %User{} = user) do
    {user_token, token} = Accounts.generate_user_session_token!(user)

    conn
    |> renew_session()
    |> put_session(:user_token, user_token)
    |> put_session(:live_socket_id, user_session_topic(token))
  end

  @doc """
  Returns to or redirects home.
  """
  def redirect_user_after_login(%Plug.Conn{} = conn, %User{} = user) do
    user_return_to = get_session(conn, :user_return_to) || maybe_redirect_to_org_invitations(user)
    conn = delete_session(conn, :user_return_to)

    try do
      redirect(conn, to: user_return_to || signed_in_path(user))
    rescue
      ArgumentError ->
        redirect(conn, to: signed_in_path(user))
    end
  end

  @doc """
  Renews the session ID and clears the whole session
  """
  def renew_session(%Plug.Conn{} = conn) do
    user_return_to = get_session(conn, :user_return_to)
    locale = get_session(conn, :locale)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:locale, locale)
    |> put_session(:user_return_to, user_return_to)
  end

  @doc """
  Logs the user out.
  """
  def log_out(%Plug.Conn{} = conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      PasswordlessWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    with %User{} = user <- conn.assigns[:current_user] do
      Activity.log_async(:user, :"user.sign_out", %{user: user})
    end

    conn
    |> renew_session()
    |> redirect(to: "/")
  end

  @doc """
  Deletes the user's session and forces all live views to reconnect (logging them out fully)
  """
  def log_out_user(%User{} = user) do
    user
    |> Accounts.get_user_session_tokens()
    |> disconnect_user_tokens(delete: true)
  end

  @doc """
  Forces all live views to reconnect for a user. Useful if their permissions have changed (eg. no longer an org member).
  """
  def disconnect_user_liveviews(%User{} = user) do
    user
    |> Accounts.get_user_session_tokens()
    |> disconnect_user_tokens()
  end

  def user_session_topic(%Token{} = token), do: "users_sessions:#{Base.url_encode64(Token.hash(token))}"

  @doc """
  Authenticates the user by looking into the session.
  """
  def fetch_current_user(%Plug.Conn{} = conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  @doc """
  Adds `:current_impersonator` to `conn.assigns.current_user` if `:impersonator_user_id` is set in the session.
  We put it on `:current_user` so that it's more easily accessible in templates.
  """
  def fetch_impersonator_user(%Plug.Conn{} = conn, _opts) do
    case {get_session(conn, :impersonator_user_id), Map.get(conn.assigns, :current_user)} do
      {impersonator_user_id, %User{} = user} when is_binary(impersonator_user_id) ->
        assign(conn, :current_user, %User{user | current_impersonator: Accounts.get_user!(impersonator_user_id)})

      _ ->
        conn
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(%Plug.Conn{} = conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        conn
        |> redirect(to: signed_in_path(user))
        |> halt()

      _ ->
        conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(%Plug.Conn{} = conn, opts) do
    cond do
      is_nil(conn.assigns[:current_user]) ->
        conn
        |> put_flash(:info, gettext("You must sign in to access this page."))
        |> maybe_store_return_to()
        |> redirect(to: ~p"/auth/sign-in")
        |> halt()

      get_session(conn, :user_totp_pending) &&
        conn.request_path != ~p"/app/user/totp" &&
          conn.request_path != ~p"/auth/sign-out" ->
        conn
        |> redirect(to: ~p"/app/user/totp")
        |> halt()

      true ->
        require_confirmed_user(conn, opts)
    end
  end

  @doc """
  Used for routes that require the user to be confirmed.
  """
  def require_confirmed_user(%Plug.Conn{} = conn, _opts) do
    with %User{} = user <- conn.assigns[:current_user], true <- User.confirmed?(user) do
      conn
    else
      _ ->
        conn
        |> redirect(to: ~p"/auth/confirm")
        |> halt()
    end
  end

  @doc """
  Used for routes that require the user to be a admin
  """
  def require_admin_user(%Plug.Conn{} = conn, _opts) do
    case {conn.assigns[:current_user], conn.assigns[:current_org], conn.assigns[:current_membership]} do
      {%User{} = user, %Org{} = org, %Membership{} = membership} ->
        if User.active?(user) and
             User.confirmed?(user) and
             Org.is_admin?(org) and
             Membership.is_or_higher?(membership, :admin) do
          conn
        else
          conn
          |> put_flash(:error, gettext("You must be an admin to access this page."))
          |> redirect(to: ~p"/")
          |> halt()
        end

      {%User{} = user, _org, _membership} ->
        conn
        |> redirect(to: signed_in_path(user))
        |> halt()

      _ ->
        conn
        |> redirect(to: ~p"/")
        |> halt()
    end

    conn
  end

  @doc """
  Used for routes that require the user to be onboarded
  """
  def require_onboarded_user(%Plug.Conn{} = conn, _opts) do
    with %User{} = user <- conn.assigns[:current_user],
         {:yes, _} <- Accounts.user_needs_onboarding?(user),
         false <- onboarding_path?(conn) do
      conn
      |> redirect(to: ~p"/app/onboarding?#{[user_return_to: return_to_path(conn)]}")
      |> halt()
    else
      _ -> conn
    end
  end

  @doc """
  Used for routes that require the user to be active.
  """
  def fetch_active_user(%Plug.Conn{} = conn, opts \\ []) do
    with %User{} = user <- conn.assigns[:current_user], false <- User.active?(user) do
      conn
      |> put_flash(
        :error,
        Keyword.get(opts, :flash, gettext("Your account is not accessible."))
      )
      |> log_out()
      |> halt()
    else
      _ -> conn
    end
  end

  def maybe_redirect_to_org_invitations(%User{} = user) do
    invitations = Organizations.list_invitations_by_user(user)

    if Enum.any?(invitations),
      do: ~p"/app/invitations"
  end

  # Private

  defp maybe_store_return_to(%Plug.Conn{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(%Plug.Conn{} = conn), do: conn

  defp signed_in_path(%User{} = user), do: PasswordlessWeb.Helpers.home_path(user)

  defp onboarding_path?(%Plug.Conn{} = conn) do
    conn.request_path == ~p"/app/onboarding"
  end

  defp return_to_path(%Plug.Conn{} = conn) do
    maybe_redirect_to_org_invitations(conn.assigns.current_user) || current_path(conn)
  end

  defp disconnect_user_tokens(session_tokens, opts \\ []) when is_list(session_tokens) do
    delete = Keyword.get(opts || [], :delete, false)

    for %Token{} = token <- session_tokens do
      PasswordlessWeb.Endpoint.broadcast(user_session_topic(token), "disconnect", %{})
      delete && Accounts.delete_user_session_token(token)
    end
  end
end

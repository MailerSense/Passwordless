defmodule PasswordlessWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PasswordlessWeb, :controller
      use PasswordlessWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts uploads images robots.txt site.webmanifest)

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: PasswordlessWeb,
        formats: [:html, :json, :xml],
        layouts: [html: PasswordlessWeb.Layouts]

      use Gettext, backend: PasswordlessWeb.Gettext

      import Phoenix.Component, only: [to_form: 2]
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def authenticated_controller do
    quote do
      use Phoenix.Controller,
        namespace: PasswordlessWeb,
        formats: [:html, :json, :xml],
        layouts: [html: PasswordlessWeb.Layouts]

      use Gettext, backend: PasswordlessWeb.Gettext

      import Phoenix.Component, only: [to_form: 2]
      import Plug.Conn

      unquote(verified_routes())

      def action(conn, _) do
        current_user = Map.fetch!(conn.assigns, :current_user)
        args = [conn, conn.params, current_user]

        apply(__MODULE__, action_name(conn), args)
      end
    end
  end

  def view do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      use Phoenix.View,
        root: "lib/passwordless_web/templates",
        namespace: PasswordlessWeb

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PasswordlessWeb.Layouts, :app},
        global_prefixes: ~w(x-)

      on_mount({PasswordlessWeb.User.Hooks, :maybe_assign_user})
      on_mount(PasswordlessWeb.Hooks.RestoreLocale)
      on_mount(PasswordlessWeb.Hooks.AllowEctoSandbox)
      on_mount({PasswordlessWeb.Hooks.ViewSetup, :reset_page_title})
      on_mount(Sentry.LiveViewHook)

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent, global_prefixes: ~w(x-)

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x-)

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      # Core UI components and translation
      use PasswordlessWeb.Components
      use Gettext, backend: PasswordlessWeb.Gettext

      import PasswordlessWeb.CoreComponents
      import PasswordlessWeb.Helpers
      import Phoenix.HTML

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: PasswordlessWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PasswordlessWeb.Endpoint,
        router: PasswordlessWeb.Router,
        statics: PasswordlessWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

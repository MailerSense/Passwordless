defmodule PasswordlessWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use PasswordlessWeb.Components
  use Gettext, backend: PasswordlessWeb.Gettext
  use Memoize

  import PasswordlessWeb.Helpers

  attr :current_page, :atom

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil

  slot :inner_block

  def tabbed_layout(assigns) do
    ~H"""
    <.box class={["flex", @class]}>
      <nav class="pc-sidebar__nav">
        <.sidebar_menu_item :for={menu_item <- @menu_items} current={@current_page} {menu_item} />
      </nav>
      <div class={["flex-grow", @inner_class]}>
        {render_slot(@inner_block)}
      </div>
    </.box>
    """
  end

  attr :current_page, :atom
  attr :menu_items, :list
  attr :title, :string

  def tabbed_menu_group(assigns) do
    ~H"""
    <nav>
      <p
        :if={Util.present?(@title)}
        class="px-4 mb-3 text-xs font-semibold text-slate-400 dark:text-slate-500 uppercase select-none"
      >
        {@title}
      </p>

      <.sidebar_menu_item :for={menu_item <- @menu_items} current={@current_page} {menu_item} />
    </nav>
    """
  end

  attr :max_width, :string, default: "lg", values: ["sm", "md", "lg", "xl", "full"]

  def footer(assigns) do
    ~H"""
    <footer class="pt-12 pb-8 bg-white">
      <.container max_width={@max_width}>
        <div class="flex flex-wrap items-center pb-8 gap-20 border-b border-slate-200">
          <.a to="/" title={Passwordless.config(:app_name)}>
            <.logo variant="dark" class="h-6" />
          </.a>
          <ul class="items-center gap-8 hidden lg:inline-flex">
            <.list_menu_items
              a_class="text-slate-900 text-base font-semibold leading-normal"
              menu_items={footer_menu_items()}
            />
          </ul>
          <div class="items-center gap-2 ml-auto hidden lg:flex">
            <.social_link
              to={Passwordless.config(:github_url)}
              platform="Github"
              icon="remix-github-fill"
            />
            <.social_link
              to={Passwordless.config(:twitter_url)}
              platform="X"
              icon="remix-twitter-x-line"
            />
            <.social_link
              to={Passwordless.config(:linkedin_url)}
              platform="LinkedIn"
              icon="remix-linkedin-fill"
            />
          </div>
        </div>
        <div class="flex flex-wrap items-center justify-between mt-8">
          <span class="text-sm text-slate-600 leading-tight">
            Copyright © {Timex.now().year} {Passwordless.config(:business_name) <>
              ". All rights reserved."}
          </span>
          <span class="text-slate-600 text-xs font-normal gap-8 hidden md:flex">
            <.a to={~p"/terms"} label={gettext("Terms of Service")} />
            <.a to={~p"/privacy"} label={gettext("Privacy Policy")} />
            <.a to={~p"/contact"} label={gettext("Contact")} />
          </span>
        </div>
      </.container>
    </footer>
    """
  end

  attr :to, :string, required: true, doc: "Link of this button"
  attr :icon, :string, required: true, doc: "Icon of this button"
  attr :class, :string, default: "", doc: "CSS class"
  attr :platform, :string, required: true, doc: "Social media platform"

  def social_link(assigns) do
    ~H"""
    <.link
      href={@to}
      class={[
        "group w-12 h-12 px-3 py-2 rounded-full text-slate-900 border border-slate-200 hover:bg-slate-900 hover:border-slate-900 justify-center items-center inline-flex transition duration-150 ease-in-out",
        @class
      ]}
      title={@platform}
    >
      <.icon name={@icon} class="w-6 h-6 bg-slate-900 group-hover:bg-primary-300" />
    </.link>
    """
  end

  @doc """
  A kind of proxy layout allowing you to pass in a user. Layout components should have little knowledge about your application so this is a way you can pass in a user and it will build a lot of the attributes for you based off the user.

  Ideally you should modify this file a lot and not touch the actual layout components like "sidebar_layout" and "stacked_layout".
  If you're creating a new layout then duplicate "sidebar_layout" or "stacked_layout" and give it a new name. Then modify this file to allow your new layout. This way live views can keep using this component and simply switch the "type" attribute to your new layout.
  """
  attr :current_user, :map, default: nil
  attr :current_page, :any, required: true
  attr :current_section, :atom, required: true
  attr :app_menu_items, :list
  attr :user_menu_items, :list
  attr :main_menu_items, :list
  attr :home_path, :string

  slot :inner_block

  def layout(assigns) do
    assigns =
      assigns
      |> assign_new(:home_path, fn -> home_path(assigns[:current_user]) end)
      |> assign_new(:user_menu_items, fn -> user_menu_items(assigns[:current_user]) end)
      |> assign_new(:main_menu_items, fn ->
        main_menu_items(assigns[:current_section], assigns[:current_user])
      end)
      |> assign_new(:app_menu_items, fn -> app_menu_items(assigns[:current_user]) end)

    assigns =
      update(assigns, :current_page, fn
        page when is_atom(page) -> page
        page when is_binary(page) -> map_active_path_to_menu_item(assigns[:main_menu_items], page)
      end)

    ~H"""
    <.stacked_layout
      home_path={@home_path}
      current_user={@current_user}
      current_page={@current_page}
      app_menu_items={@app_menu_items}
      user_menu_items={@user_menu_items}
      main_menu_items={@main_menu_items}
    >
      <:logo>
        <.logo class="h-6" />
      </:logo>

      {render_slot(@inner_block)}
    </.stacked_layout>
    """
  end

  # Shows the login buttons for all available providers. Can add a break "Or login with"
  attr :mode, :atom, default: :sign_in, values: [:sign_in, :sign_up]
  attr :conn_or_socket, :any

  def auth_providers(assigns) do
    ~H"""
    <%= if auth_provider_loaded?("google") || auth_provider_loaded?("passwordless") do %>
      <div class="flex flex-col gap-4">
        <%= if auth_provider_loaded?("google") do %>
          <.social_button
            link_type="a"
            to={~p"/auth/google"}
            variant="outline"
            logo="google"
            class="w-full"
            mode={@mode}
          />
        <% end %>

        <%= if auth_provider_loaded?("passwordless") do %>
          <% label =
            if(@mode == :sign_in,
              do: gettext("Sign In with Magic Link"),
              else: gettext("Sign Up with Magic Link")
            ) %>
          <.button
            link_type="live_patch"
            to={~p"/auth/sign-in/passwordless"}
            class="w-full"
            type="button"
            color="wireframe"
            label={label}
            with_icon
          >
            <.icon name="remix-magic-line" class="w-6 h-6" />
            {label}
          </.button>
        <% end %>
      </div>
    <% end %>
    """
  end

  @doc """
  Checks if a ueberauth provider has been enabled with the correct environment variables

  ## Examples

      iex> auth_provider_loaded?("google")
      iex> true
  """
  def auth_provider_loaded?(provider) do
    case provider do
      "google" ->
        get_in(Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth), [:client_id])

      "passwordless" ->
        true
    end
  end

  attr :li_class, :string, default: ""
  attr :a_class, :string, default: ""
  attr :menu_items, :list, default: [], doc: "list of maps with keys :method, :path, :label"

  def list_menu_items(assigns) do
    ~H"""
    <li :for={menu_item <- @menu_items} class={@li_class}>
      <.dropdown :if={Util.present?(menu_item[:menu_items])} placement="right">
        <:trigger_element>
          <span class={@a_class}>
            {menu_item.label}
            <.icon name="remix-arrow-down-s-line" class="w-5 h-5" />
          </span>
        </:trigger_element>
        <.dropdown_menu_item
          :for={child_item <- menu_item[:menu_items]}
          link_type={if child_item[:method], do: child_item[:method], else: "a"}
          to={child_item.path}
          label={child_item.label}
        >
          <.icon :if={child_item[:icon]} name={child_item[:icon]} class="w-5 h-5" />
          {child_item.label}
        </.dropdown_menu_item>
      </.dropdown>
      <.link
        :if={Util.blank?(menu_item[:menu_items])}
        href={menu_item.path}
        class={@a_class}
        title={menu_item.label}
        method={if menu_item[:method], do: menu_item[:method], else: nil}
      >
        {menu_item.label}
        <.icon :if={menu_item[:menu_items]} name="remix-arrow-down-s-line" class="w-5 h-5" />
      </.link>
    </li>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flex gap-3 my-3 text-sm leading-6 phx-no-feedback:hidden text-rose-600">
      <.icon name="remix-error-warning-line" class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :code, :string, required: true
  attr :language, :atom, values: [:javascript, :typescript], required: true
  attr :language_class, :string, default: nil
  attr :rest, :global

  def code_block(assigns) do
    assigns =
      assigns
      |> assign_new(:language_class, fn -> "language-#{@language}" end)
      |> assign_new(:id, fn -> "code-block-#{:rand.uniform(10_000_000) + 1}" end)
      |> update(:code, fn code ->
        Passwordless.Native.format_code(code, assigns[:language])
      end)

    ~H"""
    <pre id={@id} phx-hook="HighlightHook">
      <code class={[@class, @language_class, "text-sm font-mono rounded-lg"]}>{@code}</code>
    </pre>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PasswordlessWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PasswordlessWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Use for when you want to combine all form errors into one message (maybe to display in a flash)
  """
  def combine_changeset_error_messages(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    Enum.map_join(errors, "\n", fn {key, errors} ->
      "#{Phoenix.Naming.humanize(key)}: #{Enum.join(errors, ", ")}\n"
    end)
  end

  # Private

  defp menu_items_grouped?(menu_items) do
    Enum.all?(menu_items, &Map.has_key?(&1, :title))
  end

  defp map_active_path_to_menu_item(menu_items, current_path) do
    menu_items
    |> Enum.flat_map(fn menu_item ->
      if is_list(menu_item[:menu_items]) do
        menu_item[:menu_items]
      else
        [menu_item]
      end
    end)
    |> Enum.find_value(fn %{name: name, path: path} ->
      if path_active?(current_path, path), do: name
    end)
  end

  defp path_active?(current_path, to_path) do
    %{path: path} = URI.parse(current_path)

    case {path, to_path} do
      {nil, _} -> false
      {path, "/" = to} -> String.equivalent?(path, to)
      {path, to} -> String.starts_with?(path, to)
    end
  end
end

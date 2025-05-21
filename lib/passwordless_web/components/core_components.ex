defmodule PasswordlessWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use PasswordlessWeb.Components
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Helpers

  attr :current_page, :atom

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil
  attr :container, :boolean, default: true

  slot :inner_block

  def tabbed_layout(assigns) do
    ~H"""
    <div class={["pc-sidebar__tabs", @class]}>
      <nav class="pc-sidebar__nav">
        <.sidebar_menu_item :for={menu_item <- @menu_items} current={@current_page} {menu_item} />
      </nav>
      <div class={["pc-sidebar__content", @inner_class]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :current_page, :atom

  attr :menu_items, :list,
    required: true,
    doc: "list of maps with keys :name, :path, :label, :icon (atom)"

  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil
  attr :container, :boolean, default: true

  slot :inner_block
  slot :header

  def pilled_layout(assigns) do
    ~H"""
    <div class={["flex flex-col gap-6 px-8 py-6", @class]}>
      {render_slot(@header)}
      <div>
        <.tab_menu menu_items={@menu_items} current_tab={@current_page} />
      </div>
      {render_slot(@inner_block)}
    </div>
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
        class="px-4 mb-3 text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase select-none"
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
        <div class="flex flex-wrap items-center pb-8 gap-20 border-b border-gray-200">
          <.a to="/" title={Passwordless.config(:app_name)}>
            <.logo variant="dark" class="h-6" />
          </.a>
          <ul class="items-center gap-8 hidden lg:inline-flex">
            <.list_menu_items
              a_class="text-gray-900 text-base font-semibold leading-normal"
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
          <span class="text-sm text-gray-600 leading-tight">
            Copyright © {Timex.now().year} {Passwordless.config(:business_name) <>
              ". All rights reserved."}
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
        "group w-12 h-12 px-3 py-2 rounded-full text-gray-900 border border-gray-200 hover:bg-gray-900 hover:border-gray-900 justify-center items-center inline-flex transition duration-150 ease-in-out",
        @class
      ]}
      title={@platform}
    >
      <.icon name={@icon} class="w-6 h-6 bg-gray-900 group-hover:bg-primary-300" />
    </.link>
    """
  end

  @doc """
  A kind of proxy layout allowing you to pass in a user. Layout components should have little knowledge about your application so this is a way you can pass in a user and it will build a lot of the attributes for you based off the user.

  Ideally you should modify this file a lot and not touch the actual layout components like "sidebar_layout" and "stacked_layout".
  If you're creating a new layout then duplicate "sidebar_layout" or "stacked_layout" and give it a new name. Then modify this file to allow your new layout. This way live views can keep using this component and simply switch the "type" attribute to your new layout.
  """
  attr :nonce, :string, doc: "the nonce"
  attr :current_user, :map, default: nil
  attr :current_page, :any, required: true
  attr :current_section, :atom, required: true
  attr :current_subpage, :atom, default: nil
  attr :app_menu_items, :list
  attr :org_menu_items, :list
  attr :user_menu_items, :list
  attr :main_menu_items, :list
  attr :section_menu_items, :list
  attr :home_path, :string
  attr :padded, :boolean, default: true

  slot :inner_block

  def layout(assigns) do
    assigns =
      assigns
      |> assign_new(:nonce, fn -> PasswordlessWeb.CSP.get_csp_nonce() end)
      |> assign_new(:home_path, fn -> home_path(assigns[:current_user]) end)
      |> assign_new(:org_menu_items, fn -> org_menu_items(assigns[:current_user]) end)
      |> assign_new(:user_menu_items, fn -> user_menu_items(assigns[:current_user]) end)
      |> assign_new(:main_menu_items, fn ->
        main_menu_items(assigns[:current_section], assigns[:current_user])
      end)
      |> assign_new(:app_menu_items, fn -> app_menu_items(assigns[:current_user]) end)
      |> assign_new(:section_menu_items, fn -> section_menu_items(assigns[:current_user]) end)

    assigns =
      update(assigns, :current_page, fn
        page when is_atom(page) -> page
        page when is_binary(page) -> map_active_path_to_menu_item(assigns[:main_menu_items], page)
      end)

    dropdown_type =
      cond do
        assigns[:current_page] in [:home, :actions, :users, :reports, :embed, :authenticators] ->
          :app

        assigns[:current_page] in [:billing] ->
          :org

        assigns[:current_subpage] in [:app_settings, :domain] ->
          :app

        assigns[:current_subpage] in [:team, :organization, :edit_projects] ->
          :org

        true ->
          :global
      end

    assigns = assign(assigns, dropdown_type: dropdown_type)

    ~H"""
    <.sidebar_layout
      nonce={@nonce}
      home_path={@home_path}
      current_user={@current_user}
      current_page={@current_page}
      current_section={@current_section}
      current_subpage={@current_subpage}
      current_domain={@dropdown_type}
      app_menu_items={@app_menu_items}
      user_menu_items={@user_menu_items}
      main_menu_items={@main_menu_items}
      section_menu_items={@section_menu_items}
    >
      <:logo>
        <.logo variant="light" class="h-6" />
      </:logo>

      <:dropdown>
        <.topbar_dropdown
          current_user={@current_user}
          app_menu_items={@app_menu_items}
          org_menu_items={@org_menu_items}
          dropdown_type={@dropdown_type}
        />
      </:dropdown>

      {render_slot(@inner_block)}
    </.sidebar_layout>
    """
  end

  # Shows the login buttons for all available providers. Can add a break "Or login with"
  attr :mode, :atom, default: :sign_in, values: [:sign_in, :sign_up]
  attr :conn_or_socket, :any

  def auth_providers(assigns) do
    ~H"""
    <.or_break or_text="or" />

    <div class="flex gap-3">
      <.social_button
        :if={auth_provider_loaded?("google")}
        link_type="a"
        to={~p"/auth/google"}
        variant="outline"
        logo="google"
        class="w-full"
        mode={@mode}
      />

      <.social_button
        :if={auth_provider_loaded?("github")}
        link_type="a"
        to={~p"/auth/github"}
        variant="outline"
        logo="github"
        class="w-full"
        mode={@mode}
      />
    </div>
    """
  end

  # Shows a line with some text in the middle of the line. eg "Or login with"
  attr :or_text, :string

  def or_break(assigns) do
    ~H"""
    <div class="flex items-center gap-4 my-4">
      <div class="w-full h-[1px] bg-gray-200 dark:bg-gray-700/70"></div>
      <span class="text-gray-500">
        {@or_text}
      </span>
      <div class="w-full h-[1px] bg-gray-200 dark:bg-gray-700/70"></div>
    </div>
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

      "github" ->
        get_in(Application.get_env(:ueberauth, Ueberauth.Strategy.Github.OAuth), [:client_id])

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

  attr :class, :string, default: "text-base font-mono rounded-lg", doc: "any extra CSS class for the parent container"
  attr :code, :any, required: true
  attr :label, :string, default: nil
  attr :language, :atom, values: [:javascript, :typescript, :json, :html, :bash, :asciidoc], required: true
  attr :language_class, :string
  attr :rest, :global

  def code_block(assigns) do
    assigns =
      assigns
      |> assign_new(:language_class, fn -> "language-#{assigns[:language]}" end)
      |> assign_new(:id, fn -> Util.id("code-block") end)
      |> update(:code, fn code ->
        Passwordless.Formatter.format!(code, assigns[:language])
      end)

    ~H"""
    <%= if Util.present?(@label) do %>
      <div class="pc-form-field-wrapper">
        <.form_label>{@label}</.form_label>
        <pre id={@id} phx-hook="HighlightHook" {@rest}>
          <code class={[@class, @language_class]}>{@code}</code>
        </pre>
      </div>
    <% else %>
      <pre id={@id} phx-hook="HighlightHook" {@rest}>
        <code class={[@class, @language_class]}>{@code}</code>
      </pre>
    <% end %>
    """
  end

  attr :class, :any, default: nil, doc: "any extra CSS class for the parent container"
  attr :rest, :global

  slot :inner_block, required: true

  def code_line(assigns) do
    ~H"""
    <code class={[@class, "pc-code-line"]} {@rest}>
      {render_slot(@inner_block)}
    </code>
    """
  end

  attr :id, :string
  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :label, :string, default: nil
  attr :errors, :list, default: []
  attr :name, :string
  attr :rest, :global

  def code_editor(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Util.id("code-editor") end)
      |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)

    ~H"""
    <.field_error :for={msg <- @errors}>{msg}</.field_error>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :code, :any, required: true
  attr :label, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :expanded, :boolean, default: true
  attr :compact, :boolean, default: false
  attr :flex, :boolean, default: false
  attr :style, :atom, values: [:normal, :compact, :flex], default: :normal
  attr :rest, :global

  slot :label_action, required: false

  def json_block(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> Util.id("json-block") end)
      |> update(:code, fn code ->
        Passwordless.Formatter.format!(code, :json)
      end)
      |> update(:expanded, &to_string/1)

    ~H"""
    <%= if Util.present?(@label) do %>
      <div class="pc-form-field-wrapper">
        <.field_label for={@id}>
          <.div_wrapper class="flex items-center justify-between" wrap={Util.present?(@label_action)}>
            {@label}
            {render_slot(@label_action)}
          </.div_wrapper>
        </.field_label>

        <div class={[
          @class,
          "text-sm",
          case @style do
            :normal -> "rounded-lg border border-gray-300 dark:border-gray-600 shadow-m2 p-2"
            :compact -> "rounded-lg border border-gray-300 dark:border-gray-600 shadow-m2 p-1"
            :flex -> ""
          end,
          if(@disabled, do: "bg-gray-100 dark:bg-gray-700", else: "dark:bg-gray-900")
        ]}>
          <code id={@id} phx-hook="JSONHook" data-json={@code} data-expand={@expanded}></code>
        </div>
      </div>
    <% else %>
      <div class={[
        @class,
        "text-sm",
        case @style do
          :normal -> "rounded-lg border border-gray-300 dark:border-gray-600 shadow-m2 p-2"
          :compact -> "rounded-lg border border-gray-300 dark:border-gray-600 shadow-m2 p-1"
          :flex -> ""
        end,
        if(@disabled, do: "bg-gray-100 dark:bg-gray-700", else: "dark:bg-gray-900")
      ]}>
        <code id={@id} phx-hook="JSONHook" data-json={@code} data-expand={@expanded}></code>
      </div>
    <% end %>
    """
  end

  attr :class, :string, default: "", doc: "any extra CSS class for the parent container"
  attr :checked, :boolean, required: true
  attr :rest, :global

  def check_mark(assigns) do
    ~H"""
    <.icon :if={assigns[:checked]} name="remix-check-line" class="w-5 h-5" />
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

  def translate_backpex({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(PasswordlessWeb.Gettext, "backpex", msg, msg, count, opts)
    else
      Gettext.dgettext(PasswordlessWeb.Gettext, "backpex", msg, opts)
    end
  end

  # Private

  attr :wrap, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp div_wrapper(assigns) do
    ~H"""
    <%= if @wrap do %>
      <div class={@class}>
        {render_slot(@inner_block)}
      </div>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
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

  attr :current_user, :map, default: nil

  attr :app_menu_items, :list, required: false
  attr :org_menu_items, :list, required: false
  attr :dropdown_type, :atom, required: true, values: [:project, :org, :global]

  defp topbar_dropdown(%{dropdown_type: :app} = assigns) do
    ~H"""
    <.dropdown
      label={PasswordlessWeb.Helpers.user_app_name(@current_user)}
      label_icon="remix-instance-line"
      placement="right"
    >
      <.form :for={app <- @app_menu_items} for={nil} action={~p"/apps/switch"} method="post">
        <.input type="hidden" name="app_id" value={app.id} />
        <button class="pc-dropdown__menu-item">
          <.avatar src={app.settings.logo} name={app.name} size="xs" />
          <span class="line-clamp-1">{app.name}</span>
        </button>
      </.form>
      <.dropdown_menu_item link_type="live_redirect" to={~p"/app"}>
        {gettext("View all apps")}
      </.dropdown_menu_item>
    </.dropdown>
    """
  end

  defp topbar_dropdown(%{dropdown_type: :org} = assigns) do
    ~H"""
    <.dropdown
      label={PasswordlessWeb.Helpers.user_org_name(@current_user)}
      label_icon="remix-building-line"
      placement="right"
    >
      <.dropdown_menu_item link_type="live_redirect" to={~p"/organization/new"}>
        <.icon name="remix-add-line" class="w-5 h-5" />
        {gettext("New Organization")}
      </.dropdown_menu_item>
      <.form :for={org <- @org_menu_items} for={nil} action={~p"/org/switch"} method="post">
        <.input type="hidden" name="org_id" value={org.id} />
        <button class="pc-dropdown__menu-item">
          <.icon name="remix-building-line" class="w-5 h-5" />
          <span class="line-clamp-1">{org.name}</span>
        </button>
      </.form>
    </.dropdown>
    """
  end

  defp topbar_dropdown(%{dropdown_type: :global} = assigns) do
    ~H"""
    <span class="pc-dropdown__trigger-button--with-label--md-solid select-none cursor-not-allowed">
      <.icon name="remix-global-line" class="pc-dropdown__icon" />
      <span>{gettext("Global")}</span>
    </span>
    """
  end
end

defmodule PasswordlessWeb.Components.Field do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Alert
  alias PasswordlessWeb.Components.Icon

  @doc """
  Renders an input with label and error messages. If you just want an input, check out input.ex

  A `%Phoenix.HTML.FormField{}` and type may be passed to the field
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.field field={@form[:email]} type="email" />
      <.field label="Name" value="" name="name" errors={["oh no!"]} />
  """
  attr :id, :any,
    default: nil,
    doc: "the id of the input. If not passed, it will be generated automatically from the field"

  attr :icon, :string, default: nil, doc: "the icon for text inputs"

  attr :icon_class, :string,
    default: "pc-field-icon__icon",
    doc: "the icon class for select inputs"

  attr :icon_mapping, :any, default: nil, doc: "the icon mapping for select inputs"

  attr :name, :any, doc: "the name of the input. If not passed, it will be generated automatically from the field"

  attr :label, :string, doc: "the label for the input. If not passed, it will be generated automatically from the field"

  attr :value, :any, doc: "the value of the input. If not passed, it will be generated automatically from the field"

  attr :prefix, :string, default: nil, doc: "the icon mapping for select inputs"

  attr :suffix, :string, default: nil, doc: "the icon mapping for select inputs"

  attr :badge, :map, default: %{}, doc: "the icon mapping for select inputs"

  attr :option_func, :any, default: nil, doc: "the icon mapping for select inputs"

  attr :nonce, :string, doc: "the nonce"

  attr :type, :string,
    default: "text",
    values: ~w(checkbox checkbox-group color date datetime-local email file hidden month number password
               range radio-group radio-card radio-card-group search select switch tel text textarea
               time url week editor editor-select),
    doc: "the type of input"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "the size of the switch (xs, sm, md, lg or xl) or radio card (sm, md or lg)"

  attr :variant, :any, default: "outline", doc: "outline, classic - used by radio-card"

  attr :viewable, :boolean,
    default: false,
    doc: "If true, adds a toggle to show/hide the password text"

  attr :copyable, :boolean,
    default: false,
    doc: "If true, adds a copy button to the field and disables the input"

  attr :clearable, :boolean,
    default: false,
    doc: "If true, adds a clear button to clear the field value"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list,
    default: [],
    doc:
      "a list of errors to display. If not passed, it will be generated automatically from the field. Format is a list of strings."

  attr :successes, :list,
    default: [],
    doc: "a list of successes to display."

  attr :checked, :any, doc: "the checked flag for checkboxes and checkbox groups"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"
  attr :disabled_options, :list, default: [], doc: "the options to disable in a checkbox group"

  attr :no_margin, :boolean, default: false

  attr :group_layout, :string,
    values: ["row", "col", "grid"],
    default: "row",
    doc: "the layout of the inputs in a group (checkbox-group or radio-group)"

  attr :group_layout_grid_class, :string,
    default: nil,
    doc: "the layout of the inputs in a group (checkbox-group or radio-group)"

  attr :empty_message, :string,
    default: nil,
    doc: "the message to display when there are no options available, for checkbox-group or radio-group"

  attr :rows, :string, default: "4", doc: "rows for textarea"

  attr :class, :string, default: nil, doc: "the class to add to the input"
  attr :wrapper_class, :string, default: nil, doc: "the wrapper div classes"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  attr :label_class, :string, default: nil, doc: "extra CSS for your label"
  attr :label_sr_only, :boolean, default: false, doc: "extra CSS for your label"
  attr :selected, :any, default: nil, doc: "the selected value for select inputs"

  attr :required, :boolean,
    default: false,
    doc: "is this field required? is passed to the input and adds an asterisk next to the label"

  attr :required_asterix, :boolean,
    default: true,
    doc: "whether to add an asterisk next to the label if field is required"

  attr :rest, :global,
    include:
      ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
    pattern placeholder readonly required size step value name multiple prompt default year month day hour minute second builder options layout cols rows wrap checked accept),
    doc: "All other props go on the input"

  slot :action, required: false
  slot :label_action, required: false

  def field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn ->
      if assigns.multiple &&
           assigns.type not in ["checkbox-group", "radio-group", "radio-card-group"],
         do: field.name <> "[]",
         else: field.name
    end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)
    |> field()
  end

  def field(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <label class={["pc-checkbox-label", @label_class]}>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          required={@required}
          disabled={@disabled}
          class={["pc-checkbox", @class]}
          {@rest}
        />
        <span
          :if={Util.present?(@label)}
          class={[@required && @required_asterix && "pc-label--required"]}
        >
          {@label}
        </span>
      </label>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "select"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        {@label}
      </.field_label>

      <%= cond do %>
        <% @icon -> %>
          <div class="pc-select-input__wrapper">
            <Icon.icon name={@icon} class={@icon_class} />
            <select
              id={@id}
              name={@name}
              class={["pc-select-input", @class]}
              multiple={@multiple}
              required={@required}
              disabled={@disabled}
              {@rest}
            >
              <option :if={@prompt} value="">{@prompt}</option>
              {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
            </select>
          </div>
        <% @icon_mapping -> %>
          <div class="pc-select-input__wrapper">
            <Icon.icon name={@icon_mapping.(@selected || @value)} class={@icon_class} />
            <select
              id={@id}
              name={@name}
              class={["pc-select-input", @class]}
              multiple={@multiple}
              required={@required}
              disabled={@disabled}
              {@rest}
            >
              <option :if={@prompt} value="">{@prompt}</option>
              {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
            </select>
          </div>
        <% Util.present?(@prefix) or Util.present?(@suffix) -> %>
          <.div_wrapper class="flex" wrap={true}>
            <span :if={Util.present?(@prefix)} class="pc-field-prefix">
              {@prefix}
            </span>
            <select
              id={@id}
              name={@name}
              class={[
                if(Util.present?(@prefix), do: "rounded-l-none!"),
                if(Util.present?(@suffix), do: "rounded-r-none!"),
                get_class_for_type(@type, @size),
                @class
              ]}
              multiple={@multiple}
              required={@required}
              disabled={@disabled}
              {@rest}
            >
              <option :if={@prompt} value="">{@prompt}</option>
              {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
            </select>

            <span :if={Util.present?(@suffix)} class="pc-field-suffix">
              {@suffix}
            </span>
          </.div_wrapper>
        <% true -> %>
          <select
            id={@id}
            name={@name}
            class={[get_class_for_type(@type, @size), @class]}
            multiple={@multiple}
            required={@required}
            disabled={@disabled}
            {@rest}
          >
            <option :if={@prompt} value="">{@prompt}</option>
            {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
          </select>
      <% end %>

      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "editor-select"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={true}>
      <select
        id={@id}
        name={@name}
        class={[@class, "pc-editor-select-field"]}
        multiple={@multiple}
        required={@required}
        disabled={@disabled}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @selected || @value)}
      </select>
    </.field_wrapper>
    """
  end

  def field(%{type: "textarea"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        <.div_wrapper class="flex items-center justify-between" wrap={Util.present?(@label_action)}>
          {@label}
          {render_slot(@label_action)}
        </.div_wrapper>
      </.field_label>

      <textarea
        id={@id}
        name={@name}
        class={[get_class_for_type(@type, @size), @class]}
        rows={@rows}
        required={@required}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "switch", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <label class={["pc-switch-label", @label_class]}>
      <input type="hidden" name={@name} value="false" />
      <label class={["pc-switch", @disabled && "pc-switch--disabled"]}>
        <input
          id={@id}
          type="checkbox"
          name={@name}
          value="true"
          checked={@checked}
          disabled={@disabled}
          required={@required}
          class={["sr-only peer", @class]}
          {@rest}
        />

        <span class="pc-switch__fake-input"></span>
        <span class="pc-switch__fake-input-bg"></span>
      </label>
      <div class={[@required && @required_asterix && "pc-label--required"]}>{@label}</div>
    </label>
    """
  end

  def field(%{type: "checkbox-group"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        values =
          case assigns.value do
            value when is_binary(value) -> [value]
            value when is_list(value) -> value
            _ -> []
          end

        Enum.map(values, &to_string/1)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        {@label}
      </.field_label>
      <input type="hidden" name={@name} value="" />
      <div class={[
        "pc-checkbox-group",
        @group_layout == "row" && "pc-checkbox-group--row",
        @group_layout == "col" && "pc-checkbox-group--col",
        @class
      ]}>
        <%= for {label, value} <- @options do %>
          <label class="pc-checkbox-label">
            <input
              type="checkbox"
              name={@name <> "[]"}
              checked_value={value}
              unchecked_value=""
              value={value}
              checked={to_string(value) in @checked}
              hidden_input={false}
              class="pc-checkbox"
              disabled={value in @disabled_options}
              {@rest}
            />
            <div>
              {label}
            </div>
          </label>
        <% end %>

        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "radio-group"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> nil end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        {@label}
      </.field_label>
      <div class={[
        "pc-radio-group",
        @group_layout == "row" && "pc-radio-group--row",
        @group_layout == "col" && "pc-radio-group--col",
        @class
      ]}>
        <input type="hidden" name={@name} value="" />
        <%= for {label, value} <- @options do %>
          <label class="pc-checkbox-label">
            <input
              type="radio"
              name={@name}
              value={value}
              checked={
                to_string(value) == to_string(@value) || to_string(value) == to_string(@checked)
              }
              class="pc-radio"
              {@rest}
            />
            <div>
              {label}
            </div>
          </label>
        <% end %>

        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-checkbox-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "radio-card"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn -> nil end)
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:group_layout, fn -> "row" end)
      |> assign_new(:id_prefix, fn -> assigns.id || assigns.name || "radio_card" end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        class={@label_class}
      >
        {@label}
      </.field_label>
      <div class={[
        "pc-radio-card-group",
        "pc-radio-card-group--#{@group_layout}",
        @group_layout_grid_class,
        @class
      ]}>
        <input type="hidden" name={@name} value="" />
        <%= for option <- @options do %>
          <label class={[
            "pc-radio-card",
            "pc-radio-card--#{@size}",
            "pc-radio-card--#{@variant}",
            option[:disabled] && "pc-radio-card--disabled"
          ]}>
            <input
              type="radio"
              name={@name}
              id={"#{@id_prefix}_#{option[:value]}"}
              value={option[:value]}
              disabled={option[:disabled]}
              checked={
                to_string(option[:value]) == to_string(@value) ||
                  to_string(option[:value]) == to_string(@checked)
              }
              class="pc-radio-card__input"
              {@rest}
            />
            <div class="pc-radio-card__fake-input"></div>
            <div class="pc-radio-card__content">
              <div class="pc-radio-card__body">
                <div class="pc-radio-card__label">{option[:label]}</div>
                <div :if={option[:description]} class="pc-radio-card__description">
                  {option[:description]}
                </div>
              </div>

              <Icon.icon :if={option[:icon]} name={option[:icon]} class={option[:icon_class]} />
            </div>
          </label>
        <% end %>
        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-radio-card-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "radio-card-group"} = assigns) do
    assigns =
      assigns
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:group_layout, fn -> "row" end)
      |> assign_new(:id_prefix, fn -> assigns.id || assigns.name || "radio_card" end)
      |> assign_new(:checked, fn ->
        values =
          case assigns.value do
            value when is_binary(value) -> [value]
            value when is_list(value) -> value
            _ -> []
          end

        Enum.map(values, &to_string/1)
      end)

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        class={@label_class}
      >
        {@label}
      </.field_label>
      <div class={[
        "pc-radio-card-group",
        "pc-radio-card-group--#{@group_layout}",
        @group_layout_grid_class,
        @class
      ]}>
        <input type="hidden" name={@name} value="" />
        <%= for option <- @options do %>
          <label class={[
            "pc-radio-card",
            "pc-radio-card--#{@size}",
            "pc-radio-card--#{@variant}",
            (@disabled || option[:disabled]) && "pc-radio-card--disabled"
          ]}>
            <input
              type="checkbox"
              name={@name <> "[]"}
              id={"#{@id_prefix}_#{option[:value]}"}
              value={option[:value]}
              disabled={option[:disabled]}
              multiple={true}
              checked={to_string(option[:value]) in @checked}
              class="sr-only pc-radio-card__input"
              {@rest}
            />
            <div class="pc-radio-card__fake-input"></div>
            <div class="pc-radio-card__content">
              <Icon.icon :if={option[:icon]} name={option[:icon]} class={option[:icon_class]} />

              <div class="pc-radio-card__body">
                <div class="pc-radio-card__label">{option[:label]}</div>
                <div :if={option[:description]} class="pc-radio-card__description">
                  {option[:description]}
                </div>
              </div>
            </div>
          </label>
        <% end %>
        <%= if @empty_message && Enum.empty?(@options) do %>
          <div class="pc-radio-card-group--empty-message">
            {@empty_message}
          </div>
        <% end %>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      id={@id}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={@class}
      {@rest}
    />
    """
  end

  def field(%{type: "password", viewable: true} = assigns) do
    assigns =
      assign(assigns, class: [assigns.class, get_class_for_type(assigns.type, assigns.size)])

    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={@no_margin}>
      <.field_label
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        <.div_wrapper class="flex items-center justify-between" wrap={Util.present?(@label_action)}>
          {@label}
          {render_slot(@label_action)}
        </.div_wrapper>
      </.field_label>
      <div class="pc-password-field-wrapper" x-data="viewable">
        <div :if={Util.present?(@icon)} class="pc-field-icon">
          <Icon.icon name={@icon} class={@icon_class} />
        </div>
        <input
          id={@id}
          name={@name}
          x-bind:type="fieldType"
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class,
            "pc-password-field-input",
            if(Util.present?(@icon), do: "pc-field-icon__padding")
          ]}
          required={@required}
          {@rest}
        />
        <button type="button" class="pc-password-field-toggle-button" x-on:click="toggleShow">
          <span x-show="notShow" class="pc-password-field-toggle-icon-container">
            <Icon.icon name="remix-eye-line" class="pc-password-field-toggle-icon" />
          </span>
          <span x-show="show" class="pc-password-field-toggle-icon-container" style="display: none;">
            <Icon.icon name="remix-eye-off-line" class="pc-password-field-toggle-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: type, copyable: true} = assigns) when type in ["text", "url", "email"] do
    assigns =
      assign(assigns, class: [assigns.class, get_class_for_type(assigns.type, assigns.size)])

    ~H"""
    <.field_wrapper
      successes={@successes}
      errors={@errors}
      name={@name}
      class={@wrapper_class}
      no_margin={@no_margin}
    >
      <!-- Field Label -->
      <.field_label :if={Util.present?(@label)} required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <!-- Copyable Field Wrapper -->
      <div class={["pc-copyable-field-wrapper"]} x-data="copyable">
        <div class="flex">
          <span :if={Util.present?(@prefix)} class="pc-field-prefix">
            {@prefix}
          </span>
          <!-- Input Field -->
          <input
            x-ref="copyInput"
            type={@type || "text"}
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@type || "text", @value)}
            class={[
              @class,
              "pc-copyable-field-input",
              if(Util.present?(@prefix), do: "rounded-l-none!")
            ]}
            disabled={@disabled}
            {@rest}
          />
          <!-- Copy Button -->
          <button type="button" class="pc-copyable-field-button" x-on:click="doCopy">
            <!-- Copy Icon -->
            <span x-show="notCopied" class="pc-copyable-field-icon-container">
              <Icon.icon name="remix-file-copy-line" class="pc-copyable-field-icon" />
            </span>
            <!-- Copied Icon -->
            <span x-show="copied" class="pc-copyable-field-icon-container" style="display: none;">
              <Icon.icon name="remix-check-line" class="pc-copyable-field-icon" />
            </span>
          </button>
        </div>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_success :for={msg <- @successes}>{msg}</.field_success>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: type, clearable: true} = assigns) when type in ["text", "search", "url", "email"] do
    assigns =
      assign(assigns, class: [assigns.class, get_class_for_type(assigns.type, assigns.size)])

    ~H"""
    <.field_wrapper
      successes={@successes}
      errors={@errors}
      name={@name}
      class={@wrapper_class}
      no_margin={@no_margin}
    >
      <!-- Field Label -->
      <.field_label :if={Util.present?(@label)} required={@required} for={@id} class={@label_class}>
        {@label}
      </.field_label>
      <!-- Searchable Field Wrapper -->
      <div class="pc-clearable-field-wrapper" x-data="clearable">
        <span :if={Util.present?(@prefix)} class="pc-field-prefix">
          {@prefix}
        </span>
        <!-- Input Field -->
        <div class="relative">
          <div class="pc-field-icon">
            <Icon.icon name={@icon} class={@icon_class} />
          </div>
          <input
            x-ref="clearInput"
            type={@type || "text"}
            name={@name}
            id={@id}
            value={Phoenix.HTML.Form.normalize_value(@type || "text", @value)}
            class={[
              @class,
              "pc-field-icon__padding",
              "pc-clearable-field-input",
              if(Util.present?(@prefix), do: "rounded-l-none!")
            ]}
            disabled={@disabled}
            x-on:input="onInput"
            {@rest}
          />
        </div>
        <!-- Clear Button -->
        <button
          type="button"
          class="pc-clearable-field-button"
          x-show="showClearButton"
          x-on:click="doClearInput"
          style="display: none;"
          aria-label="Clear input"
        >
          <!-- Clear Icon -->
          <span class="pc-clearable-field-icon-container">
            <Icon.icon name="remix-close-line" class="pc-clearable-field-icon" />
          </span>
        </button>
      </div>
      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_success :for={msg <- @successes}>{msg}</.field_success>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

  def field(%{type: "editor"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={true}>
      <input
        id={@id}
        type={@type}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[@class, "pc-editor-field"]}
        required={@required}
        disabled={@disabled}
        {@rest}
      />
    </.field_wrapper>
    """
  end

  def field(%{type: "color"} = assigns) do
    ~H"""
    <.field_wrapper errors={@errors} name={@name} class={@wrapper_class} no_margin={true}>
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        {@label}
      </.field_label>
      <div class="pc-color-input">
        <input
          id={@id}
          type={@type}
          name={@name}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[get_class_for_type(@type, @size), @class]}
          required={@required}
          disabled={@disabled}
          {@rest}
        />
        <span>{Phoenix.HTML.Form.normalize_value(@type, @value)}</span>
      </div>
    </.field_wrapper>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def field(assigns) do
    assigns =
      assign(assigns, class: [assigns.class, get_class_for_type(assigns.type, assigns.size)])

    ~H"""
    <.field_wrapper
      errors={@errors}
      successes={@successes}
      name={@name}
      class={@wrapper_class}
      no_margin={@no_margin}
    >
      <.field_label
        :if={Util.present?(@label)}
        required={@required}
        required_asterix={@required_asterix}
        for={@id}
        class={@label_class}
      >
        {@label}
      </.field_label>

      <.div_wrapper class="flex items-center" wrap={Util.present?(@action)}>
        <%= cond do %>
          <% Util.present?(@icon) -> %>
            <div class="relative">
              <div class="pc-field-icon">
                <Icon.icon name={@icon} class={@icon_class} />
              </div>
              <input
                type={@type}
                name={@name}
                id={@id}
                value={Phoenix.HTML.Form.normalize_value(@type, @value)}
                class={["pc-field-icon__padding", @class]}
                required={@required}
                disabled={@disabled}
                {input_parameters(@type)}
                {@rest}
              />
            </div>
          <% Util.present?(@prefix) or Util.present?(@suffix) or Util.present?(@badge) -> %>
            <.div_wrapper class="flex" wrap={true}>
              <span :if={Util.present?(@prefix)} class="pc-field-prefix">
                {@prefix}
              </span>
              <input
                type={@type}
                name={@name}
                id={@id}
                value={Phoenix.HTML.Form.normalize_value(@type, @value)}
                class={[
                  if(Util.present?(@prefix), do: "rounded-l-none!"),
                  if(Util.present?(@suffix) or Util.present?(@badge), do: "rounded-r-none!"),
                  @class
                ]}
                required={@required}
                disabled={@disabled}
                {input_parameters(@type)}
                {@rest}
              />
              <Alert.alert :if={Util.present?(@badge)} {@badge} />
              <span :if={Util.present?(@suffix)} class="pc-field-suffix">
                {@suffix}
              </span>
            </.div_wrapper>
          <% true -> %>
            <input
              type={@type}
              name={@name}
              id={@id}
              value={Phoenix.HTML.Form.normalize_value(@type, @value)}
              class={@class}
              required={@required}
              disabled={@disabled}
              {input_parameters(@type)}
              {@rest}
            />
        <% end %>

        {render_slot(@action)}
      </.div_wrapper>

      <.field_error :for={msg <- @errors}>{msg}</.field_error>
      <.field_success :for={msg <- @successes}>{msg}</.field_success>
      <.field_help_text help_text={@help_text} />
    </.field_wrapper>
    """
  end

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

  attr :class, :any, default: nil
  attr :errors, :list, default: []
  attr :successes, :list, default: []
  attr :no_margin, :boolean, default: false
  attr :name, :string
  attr :rest, :global
  slot :inner_block, required: true

  def field_wrapper(assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      {@rest}
      class={[
        @class,
        "pc-form-field-wrapper",
        @no_margin && "pc-form-field-wrapper--no-margin",
        @errors != [] && "pc-form-field-wrapper--error",
        @successes != [] && "pc-form-field-wrapper--success"
      ]}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  attr :required, :boolean, default: false
  attr :required_asterix, :boolean, default: true
  slot :inner_block, required: true

  def field_label(assigns) do
    ~H"""
    <label
      for={@for}
      class={["pc-label", @class, @required && @required_asterix && "pc-label--required"]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def field_error(assigns) do
    ~H"""
    <p class="pc-form-field-error">
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Generates a generic success message.
  """
  slot :inner_block, required: true

  def field_success(assigns) do
    ~H"""
    <p class="pc-form-field-success">
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: "", doc: "extra classes for the help text"
  attr :help_text, :string, default: nil, doc: "context/help for your field"
  slot :inner_block, required: false
  attr :rest, :global

  def field_help_text(assigns) do
    ~H"""
    <div :if={render_slot(@inner_block) || @help_text} class={["pc-form-help-text", @class]} {@rest}>
      {render_slot(@inner_block) || @help_text}
    </div>
    """
  end

  def translate_field_error(args), do: translate_error(args)

  attr :id, :any
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :label, :string
  attr :class, :string, default: nil, doc: "the class to add to the input"
  attr :code_errors, :list, default: []
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"

  attr :required, :boolean,
    default: false,
    doc: "is this field required? is passed to the input and adds an asterisk next to the label"

  attr :required_asterix, :boolean,
    default: true,
    doc: "whether to add an asterisk next to the label if field is required"

  attr :rest, :global,
    include:
      ~w(autocomplete autocorrect autocapitalize disabled form max maxlength min minlength list
    pattern placeholder readonly required size step value name multiple prompt selected default year month day hour minute second builder options layout cols rows wrap checked accept)

  def otp_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(field: nil)
      |> assign(:errors, Enum.map(field.errors, &PasswordlessWeb.Components.Field.translate_field_error/1))
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:value, fn -> field.value end)
      |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)
      |> assign_new(:id, fn -> Util.id("otp-input") end)

    ~H"""
    <div class={@class} {@rest}>
      <div id={@id} phx-hook="OTPHook">
        <.field_label
          :if={Util.present?(@label)}
          required={@required}
          required_asterix={@required_asterix}
          for={"#{@id}-input-#{1}"}
        >
          {@label}
        </.field_label>
        <div
          phx-feedback-for={@name}
          class={[
            "otp-input-container flex items-center justify-between",
            @code_errors != [] && "pc-form-field-wrapper--error"
          ]}
        >
          <input
            :for={i <- 1..6}
            id={"#{@id}-input-#{i}"}
            type="text"
            class="pc-otp-input"
            disabled={@disabled}
          />
        </div>
        <.field_error :for={msg <- @code_errors}>
          {msg}
        </.field_error>
        <input
          id={@id <> "-hidden"}
          type="hidden"
          name={@name}
          class="otp-result-input"
          autofill="off"
          autocomplete="off"
        />
      </div>
    </div>
    """
  end

  # Private

  defp get_class_for_type("radio", _size), do: "pc-radio"
  defp get_class_for_type("checkbox", _size), do: "pc-checkbox"
  defp get_class_for_type("color", _size), do: "pc-color"
  defp get_class_for_type("file", _size), do: "pc-file-input"
  defp get_class_for_type("range", _size), do: "pc-range-input"
  defp get_class_for_type(_, size), do: "pc-text-input--#{size}"

  defp translate_error({msg, opts}) do
    config_translator = get_translator_from_config()

    if config_translator do
      config_translator.({msg, opts})
    else
      fallback_translate_error(msg, opts)
    end
  end

  defp fallback_translate_error(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp get_translator_from_config do
    case Application.get_env(:passwordless, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end

  defp input_parameters("range"), do: %{"phx-hook" => "ProgressInput"}
  defp input_parameters(_), do: %{}
end

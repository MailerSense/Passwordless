defmodule PasswordlessWeb.Components.BadgeSelect do
  @moduledoc false

  use Phoenix.Component

  alias PasswordlessWeb.Components.Badge
  alias PasswordlessWeb.Components.Field
  alias PasswordlessWeb.Components.Icon

  attr(:field, :any,
    doc: "the field to generate the input for. eg. `@form[:name]`. Needs to be a %Phoenix.HTML.FormField{}."
  )

  attr(:class, :string, default: nil, doc: "the class to add to the input")
  attr(:wrapper_class, :string, default: nil, doc: "the wrapper div classes")

  attr(:options, :list,
    doc:
      ~s|A list of options. eg. ["Admin", "User"] (label and value will be the same) or if you want the value to be different from the label: ["Admin": "admin", "User": "user"]. We use https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2 underneath.|,
    default: []
  )

  attr(:disabled, :boolean, default: false, doc: "indicates a disabled state")

  attr(:selected, :any, doc: "the value of the input. If not passed, it will be generated automatically from the field")

  attr(:help_text, :string, default: nil, doc: "context/help for your field")

  attr(:placeholder, :string, default: "Select an option...", doc: "The placeholder text")

  attr(:reset_placeholer, :string, default: "Reset...", doc: "The reset placeholder text")

  attr(:id, :any,
    default: nil,
    doc: "the id of the input. If not passed, it will be generated automatically from the field"
  )

  attr(:name, :any, doc: "the name of the input. If not passed, it will be generated automatically from the field")

  attr(:label, :string, doc: "the label for the input. If not passed, it will be generated automatically from the field")

  attr(:value, :any, doc: "the value of the input. If not passed, it will be generated automatically from the field")

  attr(:errors, :list,
    default: [],
    doc:
      "a list of errors to display. If not passed, it will be generated automatically from the field. Format is a list of strings."
  )

  attr(:required, :boolean, default: false, doc: "indicates a required field")

  attr(:rest, :global,
    include:
      ~w(autocomplete form max maxlength min minlength list
    pattern placeholder readonly size step value name multiple selected default year month day hour minute second builder options layout cols rows wrap checked accept),
    doc: "All other props go on the input"
  )

  def badge_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &Util.TranslationHelpers.translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:label, fn -> PhoenixHTMLHelpers.Form.humanize(field.field) end)
    |> assign_new(:selected, fn ->
      default = if assigns.required, do: List.first(assigns.options)
      Enum.find(assigns.options, default, &Util.string_equals?(&1.value, field.value))
    end)
    |> badge_select()
  end

  def badge_select(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "badge-select-#{:rand.uniform(10_000_000) + 1}" end)
      |> assign_new(:selected_idx, fn ->
        case {assigns[:options], assigns[:selected]} do
          {[_ | _] = options, %{value: value}} when not is_nil(value) ->
            Enum.find_index(options, &Util.string_equals?(&1.value, value))

          _ ->
            nil
        end
      end)

    ~H"""
    <Field.field_wrapper
      id={@id}
      name={@name}
      class={["relative", @wrapper_class]}
      errors={@errors}
      phx-hook="BadgeSelectHook"
      {wrapper_assigns(@options, @selected_idx)}
    >
      <input type="hidden" name={@name} value={@selected && @selected.value} />
      <Field.field_label for={@id}>
        {@label}
      </Field.field_label>
      <button
        type="button"
        class="custom-select relative block w-full h-[46px] px-3.5 py-2 border border-gray-300 rounded-lg shadow-m2 focus:border-primary-600 focus:ring-4 focus:ring-primary-600 dark:focus:ring-primary-700/50 dark:border-gray-600 dark:focus:border-primary-500 text-base disabled:bg-gray-100 disabled:cursor-not-allowed dark:bg-gray-950 dark:text-gray-300 dark:disabled:bg-gray-700 focus:outline-none"
        x-ref="button"
        disabled={@disabled}
        @click="open = !open"
        @keydown.escape.window="open = false"
        @keydown.arrow-up.prevent="selectedIdx = selectedIdx === 0 ? max : selectedIdx - 1"
        @keydown.arrow-down.prevent="selectedIdx = selectedIdx === max ? 0 : selectedIdx + 1"
      >
        <%= if @selected do %>
          <span class="flex items-center gap-2">
            <Badge.badge size="sm" label={@selected.label} color={@selected.color} />
            <span :if={Util.present?(@selected[:name])} class="block truncate pe-4">
              {@selected[:name]}
            </span>
          </span>
          <span class="absolute inset-y-0 right-0 flex items-center pr-2 ml-3 pointer-events-none">
            <Icon.icon
              name="remix-arrow-down-s-line"
              class="w-5 h-5 text-gray-400 dark:text-gray-500"
            />
          </span>
        <% else %>
          <span class="text-gray-400 dark:text-gray-500 flex">{@placeholder}</span>
        <% end %>
      </button>

      <ul
        x-show="open"
        x-transition:leave="transition ease-in duration-100"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        class="absolute z-20 w-full mt-1 overflow-auto text-base bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 shadow-2 rounded-lg"
        @click.away="open = false"
        tabindex="-1"
        role="listbox"
      >
        <li
          :if={not @required}
          role="option"
          class={[
            if(@selected_idx == nil, do: "bg-gray-50 dark:bg-gray-700"),
            "relative py-2 pl-3 text-gray-900 dark:text-white cursor-pointer select-none pr-9 hover:bg-gray-50 dark:hover:bg-gray-700"
          ]}
          {li_assigns(nil)}
        >
          <span :if={@reset_placeholer} class="block truncate">
            {@reset_placeholer}
          </span>
        </li>
        <li
          :for={{option, idx} <- Enum.with_index(@options)}
          role="option"
          class={[
            if(idx == @selected_idx, do: "bg-gray-50 dark:bg-gray-700"),
            "relative py-2 pl-3 text-gray-900 dark:text-white cursor-pointer select-none pr-9 hover:bg-gray-50 dark:hover:bg-gray-700"
          ]}
          {li_assigns(idx)}
        >
          <div class="flex items-center gap-2">
            <Badge.badge size="sm" label={option.label} color={option.color} />
            <span :if={option[:name]} class="block truncate">
              {option[:name]}
            </span>
          </div>
        </li>
      </ul>

      <Field.field_error :for={msg <- @errors}>{msg}</Field.field_error>
      <Field.field_help_text help_text={@help_text} />
    </Field.field_wrapper>
    """
  end

  # Private

  defp wrapper_assigns(options, selected_idx) do
    data =
      options
      |> Enum.with_index()
      |> Enum.map_join(", ", fn {%{value: value}, idx} -> "#{idx}: '#{value}'" end)

    %{
      "x-on:reset": "open = false",
      "x-data": "{
        open: false,
        options: {#{data}},
        selectedIdx: #{selected_idx || "null"},
        max: #{length(options) - 1},
        init() {
          this.$watch('selectedIdx', (value) => {
            $dispatch('selected-change', {index: value, value: this.options[value]});
          });
        }
      }"
    }
  end

  defp li_assigns(index) do
    %{
      "@click": "selectedIdx = #{index || "null"}"
    }
  end
end

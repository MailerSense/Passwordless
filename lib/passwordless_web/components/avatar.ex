defmodule PasswordlessWeb.Components.Avatar do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Icon

  attr :src, :string, default: nil, doc: "hosted avatar URL"
  attr :icon, :string, default: nil, doc: "icon name"
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]
  attr :class, :string, default: "", doc: "CSS class"

  attr :color, :string,
    default: "light",
    values: [
      "light",
      "black",
      "primary",
      "danger",
      "warning",
      "blue",
      "purple",
      "indigo",
      "fuchsia",
      "pink",
      "cyan",
      "teal",
      "sky"
    ]

  attr :variant, :string, default: "circular", values: ["circular", "rounded"]
  attr :name, :string, default: nil, doc: "name for placeholder initials"

  attr :random_color, :boolean,
    default: false,
    doc: "generates a random color for placeholder initials avatar"

  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <%= cond do %>
      <% Util.present?(@src) -> %>
        <img
          {@rest}
          src={@src}
          class={[
            "pc-avatar--with-image",
            "pc-avatar--#{@variant}",
            "pc-avatar--#{@size}",
            @class
          ]}
        />
      <% Util.present?(@name) -> %>
        <div
          {@rest}
          style={maybe_generate_random_color(@random_color, @name)}
          class={[
            "pc-avatar--with-placeholder-initials",
            "pc-avatar--#{@size}",
            "pc-avatar--#{@color}-bg",
            @class
          ]}
        >
          <span class={"pc-avatar--#{@color}-text"}>{generate_initials(@name)}</span>
        </div>
      <% Util.present?(@icon) -> %>
        <div
          {@rest}
          class={[
            "pc-avatar--with-placeholder-icon",
            "pc-avatar--#{@size}",
            "pc-avatar--#{@color}-bg",
            @class
          ]}
        >
          <Icon.icon
            name={@icon}
            class={["pc-avatar__placeholder-icon--#{@size}", "pc-avatar--#{@color}-text"]}
          />
        </div>
      <% true -> %>
        <div
          {@rest}
          class={[
            "pc-avatar--with-placeholder-icon",
            "pc-avatar--#{@size}",
            @class
          ]}
        >
          <Icon.icon
            name="hero-user-solid"
            class={["pc-avatar__placeholder-icon", "pc-avatar__placeholder-icon--#{@size}"]}
          />
        </div>
    <% end %>
    """
  end

  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]
  attr :class, :string, default: "", doc: "CSS class"
  attr :avatars, :list, default: [], doc: "list of your hosted avatar URLs"
  attr :rest, :global

  def avatar_group(assigns) do
    ~H"""
    <div {@rest} class={["pc-avatar-group--#{@size}", @class]}>
      <%= for src <- @avatars do %>
        <.avatar src={src} size={@size} class="pc-avatar-group" />
      <% end %>
    </div>
    """
  end

  attr :size, :string, default: "md", values: ["md", "lg"]
  attr :class, :string, default: nil, doc: "CSS class"
  attr :title, :string, required: true, doc: "CSS class"
  attr :subtitle, :string, default: nil, doc: "CSS class"
  attr :rest, :global

  slot :inner_block, required: false

  def avatar_entry(assigns) do
    ~H"""
    <div {@rest} class={["flex items-center gap-3", @class]}>
      {render_slot(@inner_block)}
      <div class="flex flex-col">
        <span class={"pc-avatar--avatar-entry__title-#{@size}"}>
          {@title}
        </span>
        <span :if={@subtitle} class={"pc-avatar--avatar-entry__subtitle-#{@size}"}>
          {@subtitle}
        </span>
      </div>
    </div>
    """
  end

  # Private

  defp maybe_generate_random_color(false, _), do: nil

  defp maybe_generate_random_color(true, name) do
    "background-color: #{generate_color_from_string(name)}; color: white;"
  end

  defp generate_color_from_string(string) do
    a_number =
      string
      |> String.to_charlist()
      |> Enum.reduce(0, fn x, acc -> x + acc end)

    "hsl(#{rem(a_number, 360)}, 100%, 35%)"
  end

  defp generate_initials(name) when is_binary(name) do
    word_array = String.split(name)

    if length(word_array) == 1 do
      word_array
      |> List.first()
      |> String.slice(0..1)
      |> String.upcase()
    else
      initial1 = String.first(List.first(word_array))
      initial2 = String.first(List.last(word_array))
      String.upcase(initial1 <> initial2)
    end
  end

  defp generate_initials(_) do
    ""
  end
end

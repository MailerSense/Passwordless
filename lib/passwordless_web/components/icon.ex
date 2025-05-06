defmodule PasswordlessWeb.Components.Icon do
  @moduledoc false
  use Phoenix.Component

  alias PasswordlessWeb.Components.Flags

  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A dynamic way of an icon.
  """
  def icon(%{name: "remix-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end

  def icon(%{name: "custom-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end

  def icon(%{name: "browser-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end

  def icon(%{name: "os-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end

  def icon(%{name: "flag-" <> code} = assigns) do
    assigns = assign(assigns, data_url: Flags.data_url(code))

    ~H"""
    <span
      style={"background-image: url(#{@data_url}); background-size: contain; background-repeat: no-repeat;"}
      class={["shrink-0", @class]}
      role="img"
      {@rest}
    />
    """
  end

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end
end

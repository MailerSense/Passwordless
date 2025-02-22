defmodule PasswordlessWeb.Components.Icon do
  @moduledoc false
  use Phoenix.Component

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

  def icon(%{name: "flag-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, "shrink-0", @class]} role="img" {@rest} />
    """
  end
end

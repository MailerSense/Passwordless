defmodule PasswordlessWeb.Components.PublicLayout do
  @moduledoc """
  This layout is for public pages like landing / about / pricing.
  """

  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
end

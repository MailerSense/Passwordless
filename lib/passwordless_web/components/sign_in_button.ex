defmodule PasswordlessWeb.Components.SignInButton do
  @moduledoc false
  use Phoenix.Component
  use PasswordlessWeb, :verified_routes
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.Components.Button
  import PasswordlessWeb.Components.Icon

  attr :class, :string, default: "", doc: "CSS class"
  attr :current_user, :map, default: nil, doc: "The current user"

  def sign_in_button(assigns) do
    assigns =
      assign(
        assigns,
        if(assigns.current_user,
          do: [label: gettext("Open App"), to: ~p"/home", icon: "remix-account-circle-line"],
          else: [label: gettext("Sign in"), to: ~p"/auth/sign-in", icon: "remix-account-circle-line"]
        )
      )

    ~H"""
    <.button
      to={@to}
      title={@label}
      class={@class}
      color="light"
      variant="outline"
      link_type="a"
      with_icon
    >
      <.icon name={@icon} class="w-6 h-6" />
      {@label}
    </.button>
    """
  end
end

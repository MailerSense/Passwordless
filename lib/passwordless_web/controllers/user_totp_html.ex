defmodule PasswordlessWeb.UserTOTPHTML do
  use PasswordlessWeb, :html

  def new(assigns) do
    ~H"""
    <.auth_layout title="Two-factor authentication">
      <div class="mb-4 prose prose-gray dark:prose-invert">
        <p>
          {gettext(
            "Enter the six-digit code from your device or any of your eight-character backup codes to finish logging in."
          )}
        </p>
      </div>

      <.form for={@form} action={~p"/user/totp"}>
        <.field
          field={@form[:code]}
          label={gettext("Code")}
          autocomplete="one-time-code"
          inputmode="numeric"
          pattern="\d*"
          required
          autofocus
        />

        <%= if @error_message do %>
          <.alert class="mb-5" color="danger" label={@error_message} />
        <% end %>

        <div class="flex items-center justify-between">
          <.link class="text-sm underline" href={~p"/auth/sign-out"} method="delete">
            Sign out
          </.link>
          <.button label={gettext("Verify code and sign in")} />
        </div>
      </.form>
    </.auth_layout>
    """
  end
end

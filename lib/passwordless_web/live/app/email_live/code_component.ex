defmodule PasswordlessWeb.App.EmailLive.CodeComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateLocale

  @impl true
  def update(%{template: %EmailTemplate{} = template} = assigns, socket) do
    styles =
      Enum.map(EmailTemplateLocale.styles(), fn {category, styles} ->
        {translate_style(category),
         Enum.map(
           styles,
           &[key: translate_style(&1), value: &1, disabled: not Enum.member?(template.tags, category)]
         )}
      end)

    {:ok, socket |> assign(assigns) |> assign(styles: styles)}
  end

  # Private

  defp translate_style(key) do
    Keyword.get(
      [
        email_otp: gettext("Email OTP"),
        email_otp_clean: gettext("Email OTP: Clean"),
        email_otp_card: gettext("Email OTP: Card"),
        magic_link: gettext("Magic Link"),
        magic_link_clean: gettext("Magic Link: Clean"),
        magic_link_card: gettext("Magic Link: Card")
      ],
      key,
      Phoenix.Naming.humanize(key)
    )
  end
end

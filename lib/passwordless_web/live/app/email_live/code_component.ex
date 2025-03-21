defmodule PasswordlessWeb.App.EmailLive.CodeComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.EmailTemplateVersion

  @impl true
  def update(assigns, socket) do
    styles = Enum.map(EmailTemplateVersion.styles(), fn style -> {Phoenix.Naming.humanize(style), style} end)
    {:ok, socket |> assign(assigns) |> assign(styles: styles)}
  end
end

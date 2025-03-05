defmodule PasswordlessWeb.App.EmailLive.EmailComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Locale

  @impl true
  def update(assigns, socket) do
    language = assigns.language
    languages = assigns.languages

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       languages: Enum.map(languages, fn code -> {Keyword.fetch!(Locale.languages(), code), code} end),
       flag_icon: get_flag_icon(language)
     )}
  end

  @impl true
  def handle_event("send_preview", _params, socket) do
    LiveToast.send_toast(:info, "Preview email sent.", title: gettext("Success"))

    {:noreply, socket}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp get_flag_icon(:en), do: "flag-us"
  defp get_flag_icon(:de), do: "flag-de"
  defp get_flag_icon(:fr), do: "flag-fr"
end

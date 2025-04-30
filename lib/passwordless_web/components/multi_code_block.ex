defmodule PasswordlessWeb.Components.MultiCodeBlock do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(%{codes: codes} = assigns, socket) do
    codes =
      Enum.map(codes, fn %{tab: tab, code: code, language: language} ->
        %{
          tab: tab,
          code: Passwordless.Formatter.format!(code, language),
          language: language
        }
      end)

    {:ok, socket |> assign(assigns) |> assign(tab: hd(codes).tab, code: hd(codes))}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) when is_binary(tab) do
    code = Enum.find(socket.assigns.codes, fn %{tab: t} -> t == tab end)
    {:noreply, assign(socket, tab: tab, code: code)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="pc-code-tabs">
        <div class="pc-code-tabs__buttons">
          <button
            :for={%{tab: tab} <- @codes}
            phx-click="change_tab"
            phx-value-tab={tab}
            phx-target={@myself}
            aria-label={tab}
            class={[
              "pc-code-tab",
              if(@tab == tab, do: "pc-code-tab-active", else: "pc-code-tab-inactive")
            ]}
          >
            {tab}
          </button>
        </div>
        <.copy_button size="sm" color="wireframe" title={gettext("Copy")} value={@code.code} />
      </div>
      <.code_block code={@code.code} language={@code.language} class="rounded-es-lg rounded-ee-lg" />
    </div>
    """
  end
end

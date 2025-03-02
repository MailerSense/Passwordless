defmodule PasswordlessWeb.App.DomainLive.DNSComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  @impl true
  def update(%{domain: domain} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(records: Passwordless.list_domain_record(domain))}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  attr :value, :string, required: true
  attr :priority, :string, default: nil
  attr :verified, :boolean, required: true
  attr :rest, :global, doc: "Any additional HTML attributes to add to the floating container."

  defp value_line(assigns) do
    classes =
      if assigns.verified do
        %{
          icon: "remix-checkbox-circle-line",
          text_class: "text-green-700 dark:text-green-200",
          icon_class: "text-green-700 dark:text-green-200"
        }
      else
        %{
          icon: nil,
          text_class: "text-orange-700 dark:text-orange-200",
          icon_class: nil
        }
      end

    assigns =
      assigns
      |> assign(classes)
      |> assign(elem_id: UUIDv7.generate())

    ~H"""
    <span
      id={@elem_id <> "-tooltip"}
      phx-hook="TippyHook"
      data-tippy-content={gettext("Click to copy: %{value}", value: @value)}
      {@rest}
    >
      <span
        id={@elem_id <> "-clipboard"}
        class="flex gap-1 items-center cursor-pointer"
        phx-hook="ClipboardHook"
        data-content={@value}
      >
        <div class="before-copied flex items-center gap-1">
          <.icon :if={@icon} name={@icon} class={["w-4 h-4 shrink-0", @icon_class]} />
          <span class={[@text_class]}>
            {@value}
          </span>
        </div>
        <div class="hidden text-green-700 after-copied dark:text-green-200">Copied!</div>
      </span>
    </span>
    """
  end
end

defmodule PasswordlessWeb.App.DomainLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    domain = Repo.preload(socket.assigns.current_app, :domain).domain
    records = Passwordless.list_domain_record(domain)
    changeset = Passwordless.change_domain(domain)

    {:noreply,
     socket
     |> assign(domain: domain, records: records)
     |> assign_form(changeset)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/domain")}
  end

  @impl true
  def handle_event("close_slide_over", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/domain")}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset))
  end

  defp apply_action(socket, :index) do
    assign(socket,
      page_title: gettext("Domain"),
      page_subtitle: gettext("Manage domain.")
    )
  end

  defp apply_action(socket, :change) do
    assign(socket,
      page_title: gettext("Change domain"),
      page_subtitle:
        gettext(
          "If you wish to change your sending domain, type your new domain below and press the submit button. We'll get back to you shortly."
        )
    )
  end

  attr :state, :atom, required: true, values: [:active, :inactive, :unhealthy, :under_review]
  attr :verified, :boolean, required: true
  attr :class, :any, default: ""
  attr :rest, :global, doc: "Any additional HTML attributes to add to the floating container."

  defp state_link(assigns) do
    classes =
      if assigns.verified do
        %{
          text: gettext("Domain is verified and healthy"),
          text_class: "text-green-600 dark:text-green-300"
        }
      else
        case assigns.state do
          :all_records_verified ->
            %{
              text: gettext("Domain is verified and healthy"),
              text_class: "text-green-600 dark:text-green-300"
            }

          :some_records_missing ->
            %{
              text: gettext("Domain is partially verified"),
              text_class: "text-orange-600 dark:text-orange-300"
            }

          _ ->
            %{
              text: gettext("Domain is being verified"),
              text_class: "text-orange-600 dark:text-orange-300"
            }
        end
      end

    assigns = assign(assigns, classes)

    ~H"""
    <.a
      type="button"
      to={~p"/app/settings/org/domain/dns"}
      class={["text-sm underline", @text_class]}
      link_type="live_redirect"
      label={@text}
    />
    """
  end

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

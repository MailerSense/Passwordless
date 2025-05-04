defmodule PasswordlessWeb.App.DomainLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts.User
  alias Passwordless.Domain
  alias Passwordless.Repo

  @impl true
  def mount(params, _session, socket) do
    domain_kind =
      case Map.get(params, "kind", "email") do
        "email" -> :email_domain
        "tracking" -> :tracking_domain
        _ -> nil
      end

    {:ok, apply_action(socket, socket.assigns.live_action, domain_kind)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_app = Repo.preload(socket.assigns.current_app, [:settings, :email_domain, :tracking_domain])
    changeset = Passwordless.change_app(current_app)

    domain_kind =
      case Map.get(params, "kind", "email") do
        "email" -> :email_domain
        "tracking" -> :tracking_domain
        _ -> nil
      end

    domain_assigns =
      case {socket.assigns.live_action, domain_kind} do
        {a, :email_domain} when a in [:change, :dns] -> [domain: current_app.email_domain]
        {a, :tracking_domain} when a in [:change, :dns] -> [domain: current_app.tracking_domain]
        {:new, :email_domain} -> [domain: Ecto.build_assoc(current_app, :email_domain)]
        {:new, :tracking_domain} -> [domain: Ecto.build_assoc(current_app, :tracking_domain)]
        _ -> []
      end

    socket =
      case Passwordless.get_fallback_domain(current_app, :tracking) do
        {:ok, tracking_domain} -> assign(socket, tracking_domain: tracking_domain)
        _ -> assign(socket, tracking_domain: nil)
      end

    socket =
      case Passwordless.get_fallback_domain(current_app, :email) do
        {:ok, email_domain} -> assign(socket, default_email_domain: email_domain)
        _ -> assign(socket, default_email_domain: nil)
      end

    {:noreply,
     socket
     |> assign(
       current_app: current_app,
       domain_kind: domain_kind,
       email_domain: current_app.email_domain
     )
     |> assign(domain_assigns)
     |> assign_form(changeset)
     |> apply_action(socket.assigns.live_action, domain_kind)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/domain")}
  end

  @impl true
  def handle_event("close_slide_over", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/domain")}
  end

  @impl true
  def handle_event("validate_app", %{"app" => app_params}, socket) do
    save_app(socket, app_params)
  end

  @impl true
  def handle_event("save_app", %{"app" => app_params}, socket) do
    save_app(socket, app_params)
  end

  @impl true
  def handle_event("delete_domain", _params, socket) do
    case Passwordless.teardown_domains(socket.assigns.current_app) do
      {:ok, app} ->
        {:noreply,
         socket
         |> assign(current_app: app)
         |> put_toast(
           :info,
           gettext("Domain has been deleted."),
           title: gettext("Success")
         )
         |> push_navigate(to: ~p"/domain")}

      _ ->
        {:noreply,
         socket
         |> put_toast(:error, gettext("Failed to delete domains!"), title: gettext("Error"))
         |> push_patch(to: ~p"/domain")}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    settings = Ecto.Changeset.get_field(changeset, :settings)

    socket
    |> assign(form: to_form(changeset))
    |> assign(email_tracking: settings.email_tracking)
  end

  defp apply_action(socket, :index, _kind) do
    assign(socket,
      page_title: gettext("Domain"),
      page_subtitle: gettext("Manage domain.")
    )
  end

  defp apply_action(socket, :new, _kind) do
    assign(socket,
      page_title: gettext("New domain"),
      page_subtitle: gettext("Register your own domain to improve deliverability of Email OTPs and Magic Links.")
    )
  end

  defp apply_action(socket, :dns, _kind) do
    assign(socket,
      page_title: gettext("DNS records"),
      page_subtitle:
        gettext(
          "Ensure the following DNS records are set up for your domain. This is required for sending emails from your branded domain. If you need help, please contact your domain provider. The records may take up to 48 hours to propagate."
        )
    )
  end

  defp apply_action(socket, :change, :email_domain) do
    assign(socket,
      page_title: gettext("Change domain"),
      page_subtitle:
        gettext(
          "If you change the domain, the previous one will be deleted after 1 day. Keep in mind the new one still needs to be validated."
        )
    )
  end

  defp apply_action(socket, :change, :tracking_domain) do
    assign(socket,
      page_title: gettext("Change tracking domain"),
      page_subtitle:
        gettext(
          "If you change the domain, the previous one will be deleted after 1 day. Keep in mind the new one still needs to be validated."
        )
    )
  end

  defp apply_action(socket, :delete, _kind) do
    assign(socket,
      page_title: gettext("Delete domain"),
      page_subtitle: gettext("Are you sure you want to delete this domain? This action cannot be undone.")
    )
  end

  defp domain_state_badge(%Domain{verified: true}),
    do: %{
      size: "md",
      label: gettext("Domain ready"),
      color: "success",
      variant: "rectangle",
      with_icon: true,
      override: true,
      class: "pc-field-badge"
    }

  defp domain_state_badge(_),
    do: %{
      size: "md",
      label: gettext("Pending DNS verification"),
      color: "warning",
      variant: "rectangle",
      with_icon: true,
      override: true,
      class: "pc-field-badge"
    }

  defp save_app(socket, app_params) do
    case Passwordless.update_app(socket.assigns.current_app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(current_app: app)
          |> assign(current_user: %User{socket.assigns.current_user | current_app: app})
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end

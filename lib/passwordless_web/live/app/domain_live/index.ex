defmodule PasswordlessWeb.App.DomainLive.Index do
  @moduledoc false
  use PasswordlessWeb, :live_view

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Repo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    case Repo.preload(socket.assigns.current_app, :email_domain) do
      %App{email_domain: %Domain{purpose: :email} = domain} ->
        records = Passwordless.list_domain_record(domain)
        changeset = Passwordless.change_domain(domain)

        {:noreply,
         socket
         |> assign(mode: :edit, domain: domain, records: records)
         |> assign_form(changeset)
         |> apply_action(socket.assigns.live_action)}

      _ ->
        domain = Ecto.build_assoc(socket.assigns.current_app, :email_domain)
        changeset = Passwordless.change_domain(domain)

        {:noreply,
         socket
         |> assign(mode: :new, domain: domain)
         |> assign_form(changeset)
         |> apply_action(socket.assigns.live_action)}
    end
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
  def handle_event("validate", %{"domain" => domain_params}, socket) do
    case socket.assigns[:mode] do
      :new ->
        changeset =
          socket.assigns.domain
          |> Passwordless.change_domain(domain_params)
          |> Map.put(:action, :validate)

        {:noreply, assign_form(socket, changeset)}

      :edit ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"domain" => domain_params}, socket) do
    case socket.assigns[:mode] do
      :new ->
        case Passwordless.create_domain(socket.assigns.current_app, domain_params) do
          {:ok, domain} ->
            records =
              for r <- default_domain_records(domain.name) do
                {:ok, r} = Passwordless.create_domain_record(domain, r)
                r
              end

            changeset = Passwordless.change_domain(domain)

            socket =
              socket
              |> put_toast(
                :info,
                gettext("Domain added. Please add required DNS records in your domain provider."),
                title: gettext("Success")
              )
              |> assign(mode: :edit, domain: domain, records: records)
              |> assign_form(changeset)

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      :edit ->
        {:noreply, socket}
    end
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

  defp apply_action(socket, :dns) do
    assign(socket,
      page_title: gettext("DNS records"),
      page_subtitle:
        gettext(
          "Ensure the following DNS records are set up for your domain. This is required for sending emails from your branded domain. If you need help, please contact your domain provider. The records may take up to 48 hours to propagate."
        )
    )
  end

  defp apply_action(socket, :change) do
    assign(socket,
      page_title: gettext("Change domain"),
      page_subtitle:
        gettext(
          "If you change the domain, the previous one will be deleted after 1 day. Keep in mind the new one still needs to be validated."
        )
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

  defp default_domain_records(domain) do
    {:ok, %{subdomain: subdomain}} = Domainatrex.parse(domain)

    [
      %{kind: :txt, name: "envelope.#{subdomain}", value: "v=spf1 include:amazonses.com ~all"},
      %{
        kind: :txt,
        name: "envelope.#{subdomain}",
        value: "v=DMARC1; p=none; rua=mailto:dmarc@mailersense.com;"
      },
      %{
        kind: :cname,
        name: "6gofkzgsmtm3puhejogwvpq4hdulyhbt._domainkey.#{subdomain}",
        value: "6gofkzgsmtm3puhejogwvpq4hdulyhbt.dkim.amazonses.com",
        verified: true
      },
      %{
        kind: :cname,
        name: "4pjglljley3rptdd6x6jiukdffssnfj4._domainkey.#{subdomain}",
        value: "4pjglljley3rptdd6x6jiukdffssnfj4.dkim.amazonses.com",
        verified: true
      },
      %{
        kind: :cname,
        name: "vons5ikwlowq2o4k53modgl3wtfi4eqd._domainkey.#{subdomain}",
        value: "vons5ikwlowq2o4k53modgl3wtfi4eqd.dkim.amazonses.com",
        verified: true
      }
    ]
  end
end

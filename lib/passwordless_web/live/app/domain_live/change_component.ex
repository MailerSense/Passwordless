defmodule PasswordlessWeb.App.DomainLive.ChangeComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Database.ChangesetExt
  alias Passwordless.Domain

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(validate_request(assigns.domain))}
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = validate_request(socket.assigns.domain, request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: _domain}} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :request))}
    end
  end

  @impl true
  def handle_event("save", %{"request" => request_params}, socket) do
    app = socket.assigns.app
    domain = socket.assigns.domain
    changeset = validate_request(domain, request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: new_domain}} ->
        case Passwordless.replace_domain(app, domain, %{name: new_domain}, default_domain_records(new_domain)) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_toast(:info, gettext("Domain has been changed successfully."), title: gettext("Success"))
             |> push_navigate(to: ~p"/app/domain")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> put_toast(
               :error,
               gettext("Failed to change domain: %{error}",
                 error: Jason.encode!(Util.humanize_changeset_errors(changeset))
               ),
               title: gettext("Error")
             )
             |> push_navigate(to: ~p"/app/domain")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :request))}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :request))
  end

  defp validate_request(%Domain{name: name}, params \\ %{}) do
    data = %{}
    types = %{domain: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(Map.keys(types))
    |> ChangesetExt.validate_subdomain(:domain)
    |> Ecto.Changeset.validate_change(:domain, fn
      :domain, ^name -> [{:domain, "please enter a different domain"}]
      :domain, _ -> []
    end)
  end

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

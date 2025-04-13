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
     |> assign(
       prefix:
         case assigns.domain_kind do
           :email_domain -> "auth"
           :tracking_domain -> "click"
         end,
       replacement: Ecto.get_meta(assigns.domain, :state) == :loaded
     )
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
  def handle_event("save", %{"request" => request_params}, %{assigns: %{live_action: :new}} = socket) do
    app = socket.assigns.app
    domain = socket.assigns.domain
    changeset = validate_request(domain, request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: new_domain}} ->
        creator =
          case socket.assigns.domain_kind do
            :email_domain ->
              &Passwordless.create_email_domain/2

            :tracking_domain ->
              &Passwordless.create_tracking_domain/2
          end

        case creator.(app, %{name: new_domain}) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_toast(:info, gettext("Domain has been registered."), title: gettext("Success"))
             |> push_navigate(to: ~p"/domain")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> put_toast(
               :error,
               gettext("Failed to register domain: %{error}",
                 error: Jason.encode!(Util.humanize_changeset_errors(changeset))
               ),
               title: gettext("Error")
             )
             |> push_navigate(to: ~p"/domain")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :request))}
    end
  end

  @impl true
  def handle_event("save", %{"request" => request_params}, %{assigns: %{live_action: :change}} = socket) do
    app = socket.assigns.app
    domain = socket.assigns.domain
    changeset = validate_request(domain, request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: new_domain}} ->
        replacer =
          case socket.assigns.domain_kind do
            :email_domain ->
              &Passwordless.replace_email_domain/3

            :tracking_domain ->
              &Passwordless.replace_tracking_domain/3
          end

        case replacer.(app, domain, %{name: new_domain}) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_toast(:info, gettext("Domain has been changed."), title: gettext("Success"))
             |> push_navigate(to: ~p"/domain")}

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
             |> push_navigate(to: ~p"/domain")}
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

  defp validate_request(%Domain{name: name} = domain, params \\ %{}) do
    data = %{}
    types = %{domain: :string}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))
      |> Ecto.Changeset.validate_required(Map.keys(types))
      |> ChangesetExt.validate_subdomain(:domain)

    if Ecto.get_meta(domain, :state) == :loaded do
      Ecto.Changeset.validate_change(changeset, :domain, fn
        :domain, ^name -> [{:domain, "please enter a different domain"}]
        :domain, _ -> []
      end)
    else
      changeset
    end
  end
end

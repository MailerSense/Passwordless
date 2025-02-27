defmodule PasswordlessWeb.App.DomainLive.ChangeComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Database.ChangesetExt

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_form(validate_request())}
  end

  @impl true
  def handle_event("save", %{"request" => request_params}, socket) do
    changeset = validate_request(request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: domain}} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :request))}
    end
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = validate_request(request_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, %{domain: domain}} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :request))}
    end
  end

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :request))
  end

  defp validate_request(params \\ %{}) do
    data = %{}
    types = %{domain: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(Map.keys(types))
    |> ChangesetExt.validate_subdomain(:domain)
  end
end

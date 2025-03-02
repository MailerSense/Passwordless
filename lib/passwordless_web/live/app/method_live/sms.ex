defmodule PasswordlessWeb.App.MethodLive.SMS do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    sms = Repo.preload(app, :sms).sms
    changeset = Passwordless.change_sms(sms)

    preview = """
    Your #{app.display_name} verification code is 123456. To stop receiving these messages, visit #{app.website}/sms-opt-out?code=#{app.id}.
    """

    {:ok,
     socket
     |> assign(assigns)
     |> assign(sms: sms, preview: preview)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"sms" => sms_params}, socket) do
    save_sms(socket, sms_params)
  end

  @impl true
  def handle_event("validate", %{"sms" => sms_params}, socket) do
    save_sms(socket, sms_params)
  end

  # Private

  defp save_sms(socket, params) do
    case Passwordless.update_sms(socket.assigns.sms, params) do
      {:ok, sms} ->
        changeset =
          sms
          |> Passwordless.change_sms()
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(sms: sms)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
    |> assign(enabled: Ecto.Changeset.fetch_field!(changeset, :enabled))
  end

  attr :content, :string, required: true, doc: "The content to render as markdown."
  attr :class, :string, doc: "The class to apply to the rendered markdown.", default: ""

  defp unsafe_markdown(assigns) do
    ~H"""
    <div class={[
      "prose dark:prose-invert prose-img:rounded-xl prose-img:mx-auto prose-a:text-primary-600 prose-a:dark:text-primary-300",
      @class
    ]}>
      {raw(
        Passwordless.MarkdownRenderer.to_html(@content, %Earmark.Options{
          code_class_prefix: "language-",
          escape: false
        })
      )}
    </div>
    """
  end
end

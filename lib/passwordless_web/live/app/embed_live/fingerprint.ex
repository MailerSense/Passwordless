defmodule PasswordlessWeb.App.EmbedLive.Fingerprint do
  @moduledoc false

  use PasswordlessWeb, :live_component

  alias Passwordless.App
  alias Passwordless.AppSettings
  alias Passwordless.Repo

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    app = Repo.preload(app, :settings)
    changeset = Passwordless.change_app(app)

    actions =
      Enum.map(AppSettings.actions(), fn action ->
        {Phoenix.Naming.humanize(action), action}
      end)

    icon_mapping = fn
      nil -> "remix-checkbox-circle-fill"
      "allow" -> "remix-checkbox-circle-fill"
      :allow -> "remix-checkbox-circle-fill"
      "block" -> "remix-close-circle-fill"
      :block -> "remix-close-circle-fill"
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       app: app,
       actions: actions,
       rule_conditions: rule_conditions(),
       rule_effects: rule_effects(),
       icon_mapping: icon_mapping
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    case Passwordless.update_app(socket.assigns.app, app_params) do
      {:ok, app} ->
        socket =
          socket
          |> assign(app: app)
          |> assign_form(Passwordless.change_app(app))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
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
    |> assign(default_action: settings.default_action)
  end

  defp rule_conditions,
    do: [
      %{
        id: :boolean,
        name: gettext("Boolean"),
        description: gettext("A boolean value (true/false)"),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            true;
            """,
            :typescript
          )
      },
      %{
        id: :logical_and,
        name: gettext("Logical and"),
        description: gettext("A logical and operation"),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              and: [true, false],
            }
            """,
            :typescript
          )
      },
      %{
        id: :logical_or,
        name: gettext("Logical or"),
        description: gettext("A logical or operation"),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              or: [true, false],
            }
            """,
            :typescript
          )
      },
      %{
        id: :action,
        name: gettext("Action"),
        description: gettext("Check if an action took place, and whether it was allowed or blocked."),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              action: {
                name: "action_name",
                state: "allow|block|timeout",
                within_last: {
                  days: 1,
                  hours: 1,
                  minutes: 1,
                  seconds: 1,
                },
              },
            }
            """,
            :typescript
          )
      },
      %{
        id: :ip_address,
        name: gettext("IP address"),
        description: gettext("Check if the IP address is in a list of allowed or blocked IP addresses."),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              ip_address: {
                country_code: "US",
                is_anonymous: true,
              },
            }
            """,
            :typescript
          )
      }
    ]

  defp rule_effects,
    do: [
      %{
        id: :email_otp,
        name: gettext("Email OTP"),
        description: gettext("Require the user to enter a one-time password sent to their email."),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              challenge: Passwordless.EMAIL_OTP,
              with: {
                email: "john.doe@company.com"
              }
            }
            """,
            :typescript
          )
      },
      %{
        id: :magic_link,
        name: gettext("Magic Link"),
        description: ~S"""
        Require the user to enter a magic link sent to their email.<br/>
        Allowed "with" options:
        - **email**: The email address to send the magic link to.
        - **redirect_url**: The URL to redirect the user to after the link is clicked.
        """,
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              if: true,
              then: [
                {
                  challenge: Passwordless.MAGIC_LINK,
                  with: {
                    email: "john.doe@company.com",
                    redirect_url: "https://example.com/redirect",
                  }
                }
              ],
            }
            """,
            :typescript
          )
      },
      %{
        id: :totp,
        name: gettext("Time-based OTP"),
        description: gettext("Require the user to enter a time-based OTP."),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              if: true,
              then: [
                {
                  challenge: Passwordless.TOTP
                }
              ],
            }
            """,
            :typescript
          )
      },
      %{
        id: :recovery_codes,
        name: gettext("Recovery Codes"),
        description: gettext("Require the user to enter one of their recovery codes."),
        example:
          Passwordless.Formatter.format!(
            ~S"""
            {
              if: true,
              then: [
                {
                  challenge: Passwordless.RECOVERY_CODES
                }
              ],
            }
            """,
            :typescript
          )
      }
    ]
end

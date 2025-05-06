defmodule PasswordlessWeb.User.OnboardingLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.App
  alias Passwordless.FileUploads
  alias Passwordless.Organizations
  alias Passwordless.Organizations.Membership
  alias Passwordless.Organizations.Org

  @impl true
  def mount(params, _session, socket) do
    {:ok, assign_onboarding(socket, params)}
  end

  @impl true
  def handle_event("validate_user", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> User.internal_registration_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, user_form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit_user", %{"user" => user_params}, socket) do
    case socket.assigns[:current_user] do
      %User{} = user ->
        case Accounts.update_user_and_create_org(user, user_params) do
          {:ok, %User{} = user, %Org{} = org, %Membership{} = membership} ->
            socket =
              socket
              |> assign(:current_org, org)
              |> assign(:current_user, %User{user | current_org: org, current_membership: membership})
              |> assign(:current_membership, membership)
              |> assign_onboarding()

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, user_form: to_form(changeset))}

          {:error, error} ->
            {:noreply,
             put_toast(socket, :error, gettext("User creation failed: %{error}", error: inspect(error)),
               title: gettext("Error")
             )}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate_org", %{"org" => org_params}, socket) do
    changeset =
      %Org{}
      |> Org.changeset(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, org_form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit_org", %{"org" => org_params}, socket) do
    case socket.assigns[:current_user] do
      %User{} = user ->
        case Organizations.create_org_with_owner(user, org_params) do
          {:ok, %Org{} = org, %Membership{} = membership} ->
            socket =
              socket
              |> assign(:current_org, org)
              |> update(:current_user, &%User{&1 | current_org: org, current_membership: membership})
              |> assign(:current_membership, membership)
              |> assign_onboarding()

            {:noreply, socket}

          {:error, changeset} ->
            {:noreply, assign(socket, org_form: to_form(changeset))}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate_app", %{"app" => app_params}, socket) do
    case socket.assigns[:current_user] do
      %User{current_org: %Org{} = org} = _user ->
        app_name = get_in(app_params, ["name"])

        app_params =
          app_params
          |> put_in(["settings", "display_name"], app_name)
          |> put_in(["settings", "allowlisted_ip_addresses"], [%{address: "0.0.0.0/0"}])

        changeset =
          org
          |> Ecto.build_assoc(:apps)
          |> App.changeset(app_params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, app_form: to_form(changeset))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit_app", %{"app" => app_params}, socket) do
    case socket.assigns[:current_user] do
      %User{current_org: %Org{} = org} = user ->
        app_params = maybe_add_logo(app_params, socket)
        app_name = get_in(app_params, ["name"])

        app_params =
          app_params
          |> put_in(["settings", "display_name"], app_name)
          |> put_in(["settings", "allowlisted_ip_addresses"], [%{address: "0.0.0.0/0"}])

        case Passwordless.create_full_app(org, app_params) do
          {:ok, %App{} = app} ->
            socket =
              socket
              |> assign(:current_app, app)
              |> assign(:current_user, %User{user | current_app: app})
              |> assign_onboarding()

            {:noreply, socket}

          {:error, changeset} ->
            {:noreply, assign(socket, app_form: to_form(changeset))}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_onboarding(socket, params \\ %{}) do
    case socket.assigns[:current_user] do
      %User{} = user ->
        socket =
          case Accounts.user_needs_onboarding?(user) do
            {:yes, :user} ->
              assign(socket,
                step: :user,
                user_form: to_form(User.profile_changeset(user)),
                page_title: gettext("Your account"),
                title: gettext("Welcome aboard 👋"),
                subtitle:
                  gettext(
                    "We just need a few more details to set up your account. Afterwards, you'll create your first app."
                  )
              )

            {:yes, {:org_invitation, invitations}} ->
              assign(socket,
                step: :org_invitation,
                invitations: invitations,
                page_title: gettext("Your invitations"),
                title: gettext("You've got mail 📩"),
                subtitle:
                  gettext(
                    "You have been invited to join an organization. Click on the link below to accept your invitation."
                  )
              )

            {:yes, {:app, org}} ->
              upload_opts =
                FileUploads.prepare(
                  accept: ~w(.jpg .jpeg .png .svg .webp),
                  max_entries: 1,
                  max_file_size: 5_242_880 * 2
                )

              socket
              |> assign(
                step: :app,
                org: org,
                page_title: gettext("Create an app"),
                title: gettext("Let’s build securely 🚀"),
                subtitle:
                  gettext("You can now use Passwordless to secure your app. Enter the basics and we'll get you started."),
                uploaded_files: []
              )
              |> allow_upload(:logo, upload_opts)
              |> assign_user_form(
                org
                |> Ecto.build_assoc(:apps)
                |> App.changeset(%{settings: %{logo: Passwordless.config(:app_logo)}})
              )

            :no ->
              redirect(socket, to: socket.assigns[:user_return_to] || home_path(user))
          end

        if user_return_to = Map.get(params, "user_return_to", nil) do
          assign(socket, user_return_to: user_return_to)
        else
          socket
        end

      _ ->
        socket
    end
  end

  defp assign_user_form(socket, %Ecto.Changeset{} = changeset) do
    settings = Ecto.Changeset.get_field(changeset, :settings)

    socket
    |> assign(app_form: to_form(changeset))
    |> assign(logo_src: settings.logo)
  end

  defp maybe_add_logo(user_params, socket) do
    uploaded_files = FileUploads.consume_uploaded_entries(socket, :logo)

    case uploaded_files do
      [{path, _entry} | _] ->
        put_in(user_params, [Access.key("settings", %{}), Access.key("logo")], path)

      [] ->
        user_params
    end
  end
end

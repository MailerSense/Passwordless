defmodule PasswordlessWeb.User.OnboardingLive do
  @moduledoc false
  use PasswordlessWeb, :live_view

  alias Passwordless.Accounts
  alias Passwordless.Accounts.User
  alias Passwordless.Activity
  alias Passwordless.App
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
      |> User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, user_form: to_form(changeset))}
  end

  @impl true
  def handle_event("submit_user", %{"user" => user_params}, socket) do
    case socket.assigns[:current_user] do
      %User{} = current_user ->
        case Accounts.update_user_profile(current_user, user_params) do
          {:ok, user} ->
            Activity.log_async(:"user.update_profile", %{user: user})

            socket =
              socket
              |> assign(current_user: user)
              |> assign_onboarding()

            {:noreply, socket}

          {:error, changeset} ->
            {:noreply, assign(socket, user_form: to_form(changeset))}
        end

      _ ->
        socket
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
        socket
    end
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
                title: gettext("Welcome onboard 👋"),
                subtitle: gettext("We just need a few more details to get started.")
              )

            {:yes, :org} ->
              assign(socket,
                step: :org,
                org_form: to_form(Org.changeset(%Org{}, %{email: user.email})),
                page_title: gettext("Your company"),
                title: gettext("Name your company 💼"),
                subtitle: gettext("It's just a way to group your apps, users etc.")
              )

            {:yes, {:org_invitation, invitations}} ->
              assign(socket,
                step: :org_invitation,
                invitations: invitations,
                page_title: gettext("You've got mail! 📩"),
                title: gettext("Accept your invitation")
              )

            {:yes, {:app, org}} ->
              assign(socket,
                step: :app,
                org: org,
                app_form:
                  org
                  |> Ecto.build_assoc(:apps)
                  |> App.changeset(%{name: "My First App", settings: %{website: "https://passwordless.tools"}})
                  |> to_form(),
                page_title: gettext("Create an app"),
                title: gettext("Now you're ready! 🚀"),
                subtitle: gettext("You can now create your first Passwordless app.")
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
end

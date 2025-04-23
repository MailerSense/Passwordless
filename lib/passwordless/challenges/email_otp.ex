defmodule Passwordless.Challenges.EmailOTP do
  @moduledoc """
  Email OTP flow.
  """

  @behaviour Passwordless.Challenge

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.Challenge
  alias Passwordless.Domain
  alias Passwordless.Email
  alias Passwordless.Email.Renderer
  alias Passwordless.EmailMessage
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateLocale
  alias Passwordless.EmailUnsubscribeLinkMapping
  alias Passwordless.MailerExecutor
  alias Passwordless.OTP
  alias Passwordless.Repo

  @challenge :email_otp

  @impl true
  def handle(
        %App{} = app,
        %Actor{} = actor,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: "send_otp",
        attrs: %{email: %Email{} = email}
      )
      when state in [:started, :otp_sent] do
    otp_code = OTP.generate_code()

    with {:ok, domain} <- Passwordless.get_email_domain(app),
         {:ok, authenticator} <- Passwordless.fetch_authenticator(app, :email),
         {:ok, email_template} <- get_email_template(authenticator),
         {:ok, email_template_locale} <- get_email_template_locale(actor, email_template),
         :ok <- update_existing_messages(app, action),
         {:ok, email_message} <-
           create_email_message(
             app,
             actor,
             action,
             domain,
             email,
             email_template_locale,
             authenticator,
             otp_code
           ),
         {:ok, otp} <- create_otp(authenticator, email_message, otp_code),
         {:ok, challenge} <- update_challenge_state(app, challenge, :otp_sent),
         {:ok, _job} <- enqueue_email_message(app, email_message),
         do:
           {:ok,
            %Action{
              action
              | challenge: %Challenge{
                  challenge
                  | email_message: %EmailMessage{email_message | otp: otp},
                    email_messages: [email_message | challenge.email_messages]
                }
            }}
  end

  @impl true
  def handle(
        %App{} = app,
        %Actor{} = _actor,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: "validate_otp",
        attrs: %{code: code}
      )
      when state in [:otp_sent] and is_binary(code) do
    case challenge |> Ecto.assoc(:email_message) |> Repo.one() |> Repo.preload(:otp) do
      %EmailMessage{otp: %OTP{} = otp} ->
        if OTP.valid?(otp, code) do
          with {:ok, challenge} <- update_challenge_state(app, challenge, :otp_validated) do
            {:ok, %Action{action | challenge: challenge}}
          end
        else
          {:error, :otp_invalid}
        end

      _ ->
        {:error, :otp_not_found}
    end
  end

  # Private

  defp get_email_template(%Authenticators.EmailOTP{} = authenticator) do
    Repo.preload(authenticator, :email_template).email_template
  end

  defp get_email_template_locale(%Actor{} = actor, %EmailTemplate{} = template) do
    case template
         |> Ecto.assoc(:locales)
         |> Repo.get_by(language: actor.language) do
      %EmailTemplateLocale{} = locale ->
        {:ok, locale}

      _ ->
        case template
             |> Ecto.assoc(:locales)
             |> Repo.get_by(language: :en) do
          %EmailTemplateLocale{} = locale -> {:ok, locale}
          _ -> {:error, :template_not_found}
        end
    end
  end

  defp create_email_message(
         %App{} = app,
         %Actor{} = actor,
         %Action{challenge: %Challenge{} = challenge} = action,
         %Domain{} = domain,
         %Email{} = email,
         %EmailTemplateLocale{} = locale,
         %Authenticators.EmailOTP{} = authenticator,
         otp_code
       ) do
    opts = [app: app, actor: actor, action: action]

    attrs = %{
      sender: Authenticators.EmailOTP.sender_email(authenticator, domain),
      sender_name: authenticator.sender_name,
      recipient: email.address,
      recipient_name: Actor.handle(actor),
      current: true,
      email_id: email.id,
      domain_id: domain.id,
      email_template_locale_id: locale.id,
      metadata: %{
        headers: [
          %{
            name: "List-Unsubscribe",
            value: "<#{unsubscribe_url(app, email)}>"
          },
          %{
            name: "List-Unsubscribe-Post",
            value: "List-Unsubscribe=One-Click"
          }
        ]
      }
    }

    with {:ok, message_attrs} <- Renderer.render(locale, %{otp_code: otp_code}, opts) do
      attrs = Map.merge(attrs, message_attrs)

      challenge
      |> Ecto.build_assoc(:email_messages)
      |> EmailMessage.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, %EmailMessage{} = message} ->
          {:ok, %EmailMessage{message | email: email, domain: domain}}

        error ->
          error
      end
    end
  end

  defp update_existing_messages(%App{} = app, %Action{challenge: %Challenge{} = challenge}) do
    opts = [prefix: Tenant.to_prefix(app)]

    challenge
    |> Ecto.assoc(:email_messages)
    |> where([m], m.current)
    |> Repo.update_all([set: [current: false]], opts)
    |> case do
      {count, _} when count in [0, 1] -> :ok
      _ -> :error
    end
  end

  defp create_otp(%Authenticators.EmailOTP{} = authenticator, %EmailMessage{} = email_message, otp_code)
       when is_binary(otp_code) do
    expires_at = DateTime.add(DateTime.utc_now(), authenticator.expires, :minute)

    email_message
    |> Ecto.build_assoc(:otp)
    |> OTP.changeset(%{code: otp_code, expires_at: expires_at})
    |> Repo.insert()
  end

  defp enqueue_email_message(%App{} = app, %EmailMessage{} = email_message) do
    %{app_id: app.id, email_message_id: email_message.id}
    |> MailerExecutor.new()
    |> Oban.insert()
  end

  defp update_challenge_state(%App{} = app, %Challenge{} = challenge, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    challenge
    |> Challenge.state_changeset(%{state: state})
    |> Repo.update(opts)
  end

  defp unsubscribe_url(%App{} = app, %Email{} = email) do
    with {:ok, link} <- Passwordless.create_email_unsubscribe_link(app, email) do
      PasswordlessWeb.Router.Helpers.email_subscription_url(
        PasswordlessWeb.Endpoint,
        :unsubscribe_email,
        EmailUnsubscribeLinkMapping.sign_token(link)
      )
    end
  end
end

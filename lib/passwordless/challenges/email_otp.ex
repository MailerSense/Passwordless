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
  alias Passwordless.EmailTemplateVersion
  alias Passwordless.EmailUnsubscribeLinkMapping
  alias Passwordless.Mailer
  alias Passwordless.MailerExecutor
  alias Passwordless.OTP
  alias Passwordless.Repo
  alias Swoosh.Email, as: SwooshEmail

  @challenge :email_otp

  @impl true
  def handle(
        %App{} = app,
        %Actor{} = actor,
        %Action{challenge: %Challenge{type: @challenge, state: state} = challenge} = action,
        event: "send_otp",
        attrs: %{email: %Email{} = email}
      )
      when state in [:started, :otp_sent] do
    otp_code = OTP.generate_code()

    with {:ok, domain} <- Passwordless.get_email_domain(app),
         {:ok, authenticator} <- Passwordless.fetch_authenticator(app, :email),
         {:ok, email_template} <- get_email_template(authenticator),
         {:ok, email_template_version} <- get_email_template_version(actor, email_template),
         :ok <- update_existing_messages(app, action),
         {:ok, email_message} <-
           create_email_message(
             app,
             actor,
             action,
             domain,
             email,
             email_template,
             email_template_version,
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
        %Action{challenge: %Challenge{type: @type, state: state} = challenge} = action,
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

  defp get_email_template(%Authenticators.Email{} = authenticator) do
    Repo.preload(authenticator, :email_template).email_template
  end

  defp get_email_template_version(%Actor{} = actor, %EmailTemplate{} = template) do
    case template
         |> Ecto.assoc(:versions)
         |> where([v], v.language == ^actor.language)
         |> Repo.one() do
      %EmailTemplateVersion{} = version ->
        {:ok, version}

      _ ->
        case template
             |> Ecto.assoc(:versions)
             |> where([v], v.language == :en)
             |> Repo.one() do
          %EmailTemplateVersion{} = version -> {:ok, version}
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
         %EmailTemplate{} = template,
         %EmailTemplateVersion{} = version,
         %Authenticators.Email{} = authenticator,
         otp_code
       ) do
    attrs = %{
      sender: Authenticators.Email.sender_email(authenticator, domain),
      sender_name: authenticator.sender_name,
      recipient: email.address,
      recipient_name: Actor.handle(actor),
      current: true,
      email_id: email.id,
      domain_id: domain.id,
      email_template_version_id: version.id
    }

    with {:ok, message_attrs} <-
           Renderer.render(version, %{otp_code: otp_code}, app: app, actor: actor, action: action) do
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

  defp create_otp(%Authenticators.Email{} = authenticator, %EmailMessage{} = email_message, otp_code)
       when is_binary(otp_code) do
    expires_at = DateTime.add(DateTime.utc_now(), authenticator.expires, :minute)

    email_message
    |> Ecto.build_assoc(:otp)
    |> OTP.changeset(%{code: otp_code, expires_at: expires_at})
    |> Repo.insert()
  end

  defp enqueue_email_message(
         %App{} = app,
         %EmailMessage{
           sender: sender,
           sender_name: sender_name,
           recipient: recipient,
           recipient_name: recipient_name,
           reply_to: reply_to,
           reply_to_name: reply_to_name,
           subject: subject,
           html_content: html_content,
           text_content: text_content,
           email: %Email{} = email,
           domain: %Domain{} = domain
         } = email_message
       ) do
    swoosh_email =
      SwooshEmail.new()
      |> SwooshEmail.from({sender_name, sender})
      |> SwooshEmail.to({recipient_name, recipient})
      |> SwooshEmail.subject(subject)
      |> SwooshEmail.html_body(html_content)
      |> SwooshEmail.text_body(text_content)
      |> SwooshEmail.header("List-Unsubscribe", unsubscribe_url(app, email))
      |> SwooshEmail.header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")

    %{email: Mailer.to_map(swoosh_email), domain_id: domain.id}
    |> MailerExecutor.new()
    |> Oban.insert()
  end

  defp update_challenge_state(%App{} = app, %Challenge{} = challenge, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    challenge
    |> Challenge.state_changeset(%{state: state})
    |> Repo.update(opts)
  end

  defp update_action_state(%App{} = app, %Action{} = action, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    action
    |> Action.state_changeset(%{state: state})
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

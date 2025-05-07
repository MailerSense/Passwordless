defmodule Passwordless.Challenges.EmailOTP do
  @moduledoc """
  Email OTP flow.
  """

  @behaviour Passwordless.Challenge

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.Action
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.Cache
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
  alias Passwordless.User

  @challenge :email_otp

  @impl true
  def handle(
        %App{} = app,
        %User{} = user,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: "send_otp",
        attrs: %{email: %Email{} = email}
      )
      when state in [:started, :otp_sent] do
    otp_code = OTP.generate_code()

    with :ok <- rate_limit_reached?(app, email),
         :ok <- Passwordless.email_opted_out?(app, email),
         {:ok, email} <- update_email_authenticators(email),
         {:ok, domain} <- Passwordless.get_fallback_domain(app, :email),
         {:ok, authenticator} <- Passwordless.fetch_authenticator(app, :email_otp),
         {:ok, email_template} <- get_email_template(authenticator),
         {:ok, email_template_locale} <- get_email_template_locale(user, email_template),
         :ok <- update_existing_messages(app, action),
         {:ok, email_message} <-
           create_email_message(
             app,
             user,
             action,
             domain,
             email,
             email_template_locale,
             authenticator,
             otp_code
           ),
         {:ok, _otp} <- create_otp(app, authenticator, email_message, otp_code),
         {:ok, _challenge} <- update_challenge_state(app, challenge, :otp_sent),
         {:ok, _job} <- enqueue_email_message(app, domain, email_message),
         :ok <- apply_rate_limit(app, authenticator, email),
         do: {:ok, Repo.preload(action, Action.preloads())}
  end

  @impl true
  def handle(
        %App{} = app,
        %User{} = _actor,
        %Action{challenge: %Challenge{kind: @challenge, state: state} = challenge} = action,
        event: "validate_otp",
        attrs: %{code: code}
      )
      when state in [:otp_sent, :otp_invalid] and is_binary(code) do
    case challenge |> Ecto.assoc(:email_message) |> Repo.one() |> Repo.preload([:otp, :email]) do
      %EmailMessage{otp: %OTP{} = otp, email: %Email{} = email} ->
        cond do
          OTP.expired?(otp) ->
            {:error, :otp_not_found}

          OTP.valid?(otp, code) ->
            with {:ok, _email} <- update_email_verified(email),
                 {:ok, challenge} <- update_challenge_state(app, challenge, :otp_validated),
                 do: {:ok, %Action{action | challenge: challenge}}

          true ->
            with {:ok, _otp} <- increment_otp_attempts(app, otp),
                 {:ok, challenge} <- update_challenge_state(app, challenge, :otp_invalid),
                 do: {:ok, %Action{action | challenge: challenge}}
        end

      _ ->
        {:error, :otp_not_found}
    end
  end

  # Private

  defp get_email_template(%Authenticators.EmailOTP{} = authenticator) do
    case Repo.preload(authenticator, :email_template) do
      %Authenticators.EmailOTP{email_template: %EmailTemplate{} = template} ->
        {:ok, template}

      _ ->
        {:error, :email_template_not_found}
    end
  end

  defp get_email_template_locale(%User{} = user, %EmailTemplate{} = template) do
    case template
         |> Ecto.assoc(:locales)
         |> Repo.get_by(language: user.language) do
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
         %User{} = user,
         %Action{challenge: %Challenge{} = challenge} = action,
         %Domain{} = domain,
         %Email{} = email,
         %EmailTemplateLocale{} = locale,
         %Authenticators.EmailOTP{} = authenticator,
         otp_code
       ) do
    opts = [app: app, user: user, action: action]

    link = Passwordless.create_email_unsubscribe_link!(app, email)

    attrs = %{
      sender: Authenticators.EmailOTP.sender_email(authenticator, domain),
      sender_name: authenticator.sender_name,
      recipient: email.address,
      reply_to: "hello@passwordless.tools",
      reply_to_name: "Passwordless Support",
      current: true,
      email_id: email.id,
      domain_id: domain.id,
      email_template_locale_id: locale.id,
      metadata: %{
        headers: [
          %{
            name: "List-Unsubscribe",
            value: "<#{unsubscribe_url(link)}>"
          },
          %{
            name: "List-Unsubscribe-Post",
            value: "List-Unsubscribe=One-Click"
          }
        ]
      }
    }

    render_attrs = %{unsubscribe_url: unsubscribe_page_url(link), otp_code: otp_code}

    with {:ok, message_attrs} <- Renderer.render(locale, render_attrs, opts) do
      opts = [prefix: Tenant.to_prefix(app)]
      attrs = Map.merge(attrs, message_attrs)

      challenge
      |> Ecto.build_assoc(:email_messages, opts)
      |> EmailMessage.changeset(attrs, opts)
      |> Repo.insert(opts)
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

  defp create_otp(%App{} = app, %Authenticators.EmailOTP{} = authenticator, %EmailMessage{} = email_message, otp_code)
       when is_binary(otp_code) do
    opts = [prefix: Tenant.to_prefix(app)]
    expires_at = DateTime.add(DateTime.utc_now(), authenticator.expires, :minute)

    email_message
    |> Ecto.build_assoc(:otp)
    |> OTP.changeset(%{code: otp_code, expires_at: expires_at}, opts)
    |> Repo.insert(opts)
  end

  defp enqueue_email_message(%App{} = app, %Domain{} = domain, %EmailMessage{} = email_message) do
    %{app_id: app.id, domain_id: domain.id, email_message_id: email_message.id}
    |> MailerExecutor.new()
    |> Oban.insert()
  end

  defp update_action_state(%App{} = app, %Action{} = action, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    action
    |> Action.state_changeset(%{state: state})
    |> Repo.update(opts)
  end

  defp update_challenge_state(%App{} = app, %Challenge{} = challenge, state) do
    opts = [prefix: Tenant.to_prefix(app)]

    challenge
    |> Challenge.state_changeset(%{state: state})
    |> Repo.update(opts)
  end

  defp increment_otp_attempts(%App{} = app, %OTP{} = otp) do
    opts = [prefix: Tenant.to_prefix(app)]

    otp
    |> OTP.changeset(%{attempts: otp.attempts + 1})
    |> Repo.update(opts)
  end

  defp update_email_authenticators(%Email{authenticators: authenticators} = email) do
    if @challenge in authenticators do
      {:ok, email}
    else
      email
      |> Email.changeset(%{authenticators: [@challenge | authenticators]})
      |> Repo.update()
    end
  end

  defp update_email_verified(%Email{} = email) do
    email
    |> Email.changeset(%{verified: true})
    |> Repo.update()
  end

  defp unsubscribe_url(%EmailUnsubscribeLinkMapping{} = link) do
    PasswordlessWeb.Router.Helpers.email_subscription_url(
      PasswordlessWeb.Endpoint,
      :unsubscribe_email,
      EmailUnsubscribeLinkMapping.sign_token(link)
    )
  end

  defp unsubscribe_page_url(%EmailUnsubscribeLinkMapping{} = link) do
    PasswordlessWeb.Router.Helpers.email_subscription_page_url(
      PasswordlessWeb.Endpoint,
      :show,
      EmailUnsubscribeLinkMapping.sign_token(link)
    )
  end

  defp rate_limit_reached?(%App{} = app, %Email{} = email) do
    if Cache.exists?(rate_limit_key(app, email)),
      do: {:error, :rate_limit_reached},
      else: :ok
  end

  defp apply_rate_limit(%App{} = app, %Authenticators.EmailOTP{} = authenticator, %Email{} = email) do
    Cache.put(rate_limit_key(app, email), true, ttl: :timer.seconds(authenticator.resend))
    :ok
  end

  defp rate_limit_key(%App{id: id}, %Email{address: address}), do: "email_otp:#{id}:#{address}"
end

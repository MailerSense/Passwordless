defmodule Passwordless.Flows.EmailOTP do
  @moduledoc """
  Email OTP flow.
  """

  import Ecto.Query

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Authenticators
  alias Passwordless.Challenge
  alias Passwordless.Email
  alias Passwordless.EmailMessage
  alias Passwordless.EmailTemplate
  alias Passwordless.EmailTemplateVersion
  alias Passwordless.Mailer
  alias Passwordless.MailerExecutor
  alias Passwordless.OTP
  alias Passwordless.Repo
  alias Swoosh.Email, as: SwooshEmail

  @flow :email_otp
  @otp_size 6
  @otp_expiry :timer.minutes(10)

  @doc """
  Handle the logic for sending an OTP email.
  """
  def handle(%App{} = app, %Actor{} = actor, %Action{challenge: %Challenge{flow: @flow, state: state}} = action,
        event: :send_otp,
        attrs: %{email: %Email{} = email, authenticator: %Authenticators.Email{} = authenticator}
      )
      when state in [:otp_sent, :otp_invalid] do
    otp_code = Util.random_numeric_string(@otp_size)

    with {:ok, email_template} <- get_email_template(authenticator),
         {:ok, email_template_version} <- get_latest_template_version(actor, email_template),
         {:ok, email_message} <-
           create_email_message(action, email, email_template, email_template_version, otp_code),
         :ok <- update_existing_messages(app, action),
         {:ok, _otp} <- create_otp(email_message, otp_code),
         {:ok, action} <- update_action_state(action, :otp_sent),
         :ok <- queue_email_for_sending(email_message, email, otp_code),
         do: {:ok, action}
  end

  def handle(%App{} = app, %Actor{} = actor, %Action{challenge: %Challenge{flow: @flow, state: state}} = action,
        event: :validate_otp,
        attrs: %{code: code}
      )
      when state in [:otp_sent] and is_binary(code) do
    case action
         |> Ecto.assoc(:email_message)
         |> Repo.one()
         |> Repo.preload(:otp) do
      %OTP{} = otp ->
        if OTP.valid?(otp, code) do
          update_action_state(action, :allowed)
        else
          {:error, :otp_invalid}
        end

      nil ->
        {:error, :otp_not_found}
    end
  end

  # Private

  defp get_email_template(%Authenticators.Email{} = authenticator) do
    Repo.preload(authenticator, :email_template).email_template
  end

  defp get_latest_template_version(%Actor{} = actor, %EmailTemplate{} = template) do
    template_version =
      template
      |> Ecto.assoc(:versions)
      |> where([v], v.language == ^actor.language)
      |> Repo.one()

    if template_version do
      {:ok, template_version}
    else
      template_version =
        template
        |> Ecto.assoc(:versions)
        |> where([v], v.language == :en)
        |> Repo.one()

      if template_version do
        {:ok, template_version}
      else
        {:error, :template_not_found}
      end
    end
  end

  defp create_email_message(
         %Action{} = action,
         %Email{} = email,
         %EmailTemplate{} = template,
         %EmailTemplateVersion{} = version,
         otp_code
       ) do
    # Render the email content with the OTP code
    html_content = render_email_content(version.html_body || "", otp_code)
    text_content = render_email_content(version.text_body || "", otp_code)

    # Create the email message
    %EmailMessage{}
    |> EmailMessage.changeset(%{
      state: :created,
      sender: Application.get_env(:passwordless, :sender_email, "noreply@example.com"),
      sender_name: Application.get_env(:passwordless, :sender_name, "Passwordless"),
      recipient: email.address,
      recipient_name: nil,
      subject: version.subject,
      preheader: version.preheader,
      text_content: text_content,
      html_content: html_content,
      current: true,
      action_id: action.id,
      email_id: email.id,
      email_template_id: template.id
    })
    |> Repo.insert()
  end

  defp update_existing_messages(%App{} = app, %Action{} = action) do
    opts = [prefix: Tenant.to_prefix(app)]

    action
    |> Ecto.assoc(:email_messages)
    |> where([m], m.current == true)
    |> Repo.update_all([set: [current: false]], opts)
    |> case do
      {count, _} when count in [0, 1] -> :ok
      _ -> :error
    end
  end

  defp create_otp(%EmailMessage{} = email_message, otp_code) when is_binary(otp_code) do
    expires_at = DateTime.add(DateTime.utc_now(), @otp_expiry, :millisecond)

    email_message
    |> Ecto.build_assoc(:otp)
    |> OTP.changeset(%{code: otp_code, expires_at: expires_at})
    |> Repo.insert()
  end

  defp queue_email_for_sending(%EmailMessage{} = email_message, %Email{} = email, otp_code) do
    swoosh_email =
      SwooshEmail.new()
      |> SwooshEmail.from({email_message.sender_name, email_message.sender})
      |> SwooshEmail.to({email_message.recipient_name, email_message.recipient})
      |> SwooshEmail.subject(email_message.subject)
      |> SwooshEmail.html_body(email_message.html_content)
      |> SwooshEmail.text_body(email_message.text_content)

    with {:ok, _job} <-
           %{email: Mailer.to_map(swoosh_email)}
           |> MailerExecutor.new()
           |> Oban.insert() do
      email_message
      |> EmailMessage.changeset(%{state: :submitted})
      |> Repo.update()
    end
  end

  defp render_email_content(content, otp_code) do
    # Replace placeholders with actual values
    # This is a simple implementation, you might want to use a proper template engine
    String.replace(content, "{{otp_code}}", otp_code)
  end

  defp update_action_state(%Action{} = action, state) do
    action
    |> Action.state_changeset(%{state: state})
    |> Repo.update()
  end
end

defmodule PasswordlessWeb.User.SecurityLive do
  @moduledoc false

  use PasswordlessWeb, :live_view
  use Gettext, backend: PasswordlessWeb.Gettext

  import PasswordlessWeb.SettingsLayoutComponent

  alias Passwordless.Accounts
  alias Passwordless.Accounts.TOTP
  alias Passwordless.Accounts.User

  @qrcode_size 264

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Security")
      |> assign(backup_codes: nil, current_password: nil)
      |> reset_assigns(Accounts.get_user_totp(socket.assigns.current_user))

    {:ok, socket}
  end

  def totp_form(assigns) do
    ~H"""
    <div class="mb-10">
      <%= if @secret_display == :as_text do %>
        <div class="prose prose-gray dark:prose-invert">
          <p>
            To {if @current_totp, do: "change", else: "enable"} two-factor authentication, enter the secret below into your two-factor authentication app in your phone.
          </p>
        </div>

        <div class="flex items-center justify-start px-4 py-8 sm:px-0">
          <div class="p-5 border-4 border-slate-300 border-dashed rounded-lg dark:border-slate-700">
            <div class="text-xl font-bold" id="totp-secret">
              {format_secret(@editing_totp.secret)}
            </div>
          </div>
        </div>

        <div class="prose prose-gray dark:prose-invert">
          <p>
            Or <a href="#" class="underline" phx-click="display_secret_as_qrcode">scan the QR Code</a>
            instead.
          </p>
        </div>
      <% else %>
        <div class="prose prose-gray dark:prose-invert">
          <p>
            To {if @current_totp, do: "change", else: "enable"} two-factor authentication, scan the image below with the two-factor authentication app in your phone and then enter the  authentication code at the bottom. If you can't use QR Code,
            <a href="#" class="underline" phx-click="display_secret_as_text">enter your secret</a>
            manually.
          </p>
        </div>

        <div class="mt-10 text-center">
          <div class="inline-block">
            {generate_qrcode(@qrcode_uri)}
          </div>
        </div>
      <% end %>
    </div>

    <.form id="form-update-totp" for={@totp_form} phx-submit="update_totp">
      <.field
        field={@totp_form[:code]}
        label="Authentication code"
        placeholder="eg. 123456"
        autocomplete="one-time-code"
        inputmode="numeric"
        pattern="\d*"
        required
      />

      <div class="flex justify-end gap-3">
        <.button
          id="cancel-totp"
          type="button"
          color="light"
          label={gettext("Cancel")}
          phx-click="cancel_totp"
        />
        <.button
          type="submit"
          icon="remix-verified-badge-line"
          label={gettext("Verify Code")}
          phx-disable-with="Verifying..."
        />
      </div>
    </.form>

    <%= if @current_totp do %>
      <div class="mt-10 prose prose-gray dark:prose-invert">
        <p>
          You may also
          <a href="#" id="show-backup" class="underline" phx-click="show_backup_codes">
            see your available backup codes
          </a>
          or
          <a
            href="#"
            id="disable-totp"
            phx-click="disable_totp"
            data-confirm="Are you sure you want to disable Two-factor authentication?"
          >
            disable two-factor authentication
          </a>
          altogether.
        </p>
      </div>
    <% end %>
    """
  end

  def enable_form(assigns) do
    ~H"""
    <%= if @has_password do %>
      <.form id="submit-totp-form" for={@user_form} phx-submit="submit_totp" phx-change="change_totp">
        <.field
          type="password"
          field={@user_form[:current_password]}
          value={@current_password}
          phx-debounce="blur"
          label={gettext("Password")}
          placeholder={gettext("Enter your password")}
          autocomplete="current-password"
          viewable={true}
          required
        />

        <div class="flex justify-end">
          <.button
            icon="remix-lock-line"
            label={if @current_totp, do: gettext("Update 2FA"), else: gettext("Enable 2FA")}
            phx-disable-with={gettext("Working...")}
          />
        </div>
      </.form>
    <% else %>
      <.p>
        {gettext("You need to set your password to access features like 2FA.")}
      </.p>
      <.a
        to={~p"/app/password"}
        label={gettext("Go to password settings")}
        class="underline font-semibold text-slate-900 dark:text-white"
        link_type="live_redirect"
      />
    <% end %>
    """
  end

  def backup_codes(assigns) do
    ~H"""
    <.modal title="Backup codes" on_cancel={Phoenix.LiveView.JS.push("hide_backup_codes")}>
      <div class="prose prose-gray dark:prose-invert">
        <p>
          Two-factor authentication is enabled. In case you lose access to your
          phone, you will need one of the backup codes below. <b>Keep these backup codes safe</b>. You can also generate
          new codes at any time.
        </p>
      </div>

      <div class="grid grid-cols-1 gap-3 mt-5 mb-10 md:grid-cols-2">
        <%= for backup_code <- @backup_codes do %>
          <div class="flex items-center justify-center p-3 font-mono bg-slate-300 rounded dark:bg-slate-700">
            <h4>
              <%= if backup_code.used_at do %>
                <del class="line-through">{backup_code.code}</del>
              <% else %>
                {backup_code.code}
              <% end %>
            </h4>
          </div>
        <% end %>
      </div>

      <div class="flex justify-between">
        <%= if @editing_totp do %>
          <.button
            type="button"
            color="light"
            id="regenerate-backup"
            phx-click="regenerate_backup_codes"
            data-confirm="Are you sure? This will generate new backup codes and invalidate the old ones."
            label="Regenerate backup codes"
          />
        <% else %>
          <div></div>
        <% end %>

        <.button
          id="close-backup-codes"
          label="Close"
          phx-click={Phoenix.LiveView.JS.push("hide_backup_codes")}
        />
      </div>
    </.modal>
    """
  end

  @impl true
  def handle_event("show_backup_codes", _, socket) do
    {:noreply, assign(socket, :backup_codes, socket.assigns.editing_totp.backup_codes)}
  end

  @impl true
  def handle_event("hide_backup_codes", _, socket) do
    {:noreply, assign(socket, :backup_codes, nil)}
  end

  @impl true
  def handle_event("regenerate_backup_codes", _, socket) do
    totp = Accounts.regenerate_user_totp_backup_codes(socket.assigns.editing_totp)

    socket =
      socket
      |> assign(backup_codes: totp.backup_codes)
      |> assign(editing_totp: totp)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_totp", %{"totp" => params}, socket) do
    case Accounts.upsert_user_totp(socket.assigns.editing_totp, params) do
      {:ok, current_totp} ->
        {:noreply,
         socket
         |> assign(backup_codes: current_totp.backup_codes)
         |> reset_assigns(current_totp)}

      {:error, changeset} ->
        {:noreply, assign(socket, totp_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("disable_totp", _, socket) do
    Accounts.delete_user_totp(socket.assigns.editing_totp)
    {:noreply, reset_assigns(socket, nil)}
  end

  @impl true
  def handle_event("display_secret_as_qrcode", _, socket) do
    {:noreply, assign(socket, :secret_display, :as_qrcode)}
  end

  @impl true
  def handle_event("display_secret_as_text", _, socket) do
    {:noreply, assign(socket, :secret_display, :as_text)}
  end

  @impl true
  def handle_event("change_totp", %{"user" => %{"current_password" => current_password}}, socket) do
    {:noreply, assign_user_form(socket, current_password)}
  end

  @impl true
  def handle_event("submit_totp", %{"user" => %{"current_password" => current_password}}, socket) do
    socket = assign_user_form(socket, current_password)

    if socket.assigns.user_form.source.valid? do
      user = socket.assigns.current_user

      app = Passwordless.config(:app_name)
      secret = NimbleTOTP.secret()
      qrcode_uri = NimbleTOTP.otpauth_uri("#{app}:#{user.email}", secret, issuer: app)

      editing_totp = socket.assigns.current_totp || %TOTP{user_id: user.id}
      editing_totp = %TOTP{editing_totp | secret: secret, code: nil}

      totp_form =
        editing_totp
        |> TOTP.changeset()
        |> to_form()

      socket =
        socket
        |> assign(totp_form: totp_form)
        |> assign(qrcode_uri: qrcode_uri)
        |> assign(editing_totp: editing_totp)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_totp", _, socket) do
    {:noreply, reset_assigns(socket, socket.assigns.current_totp)}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # Private

  defp reset_assigns(socket, totp) do
    socket
    |> assign(current_totp: totp)
    |> assign(secret_display: :as_qrcode)
    |> assign(editing_totp: nil)
    |> assign(totp_form: nil)
    |> assign(qrcode_uri: nil)
    |> assign_user_form(nil)
  end

  defp assign_user_form(socket, current_password) do
    user = socket.assigns.current_user
    user_form = user |> Accounts.validate_user_current_password(current_password) |> to_form()

    socket
    |> assign(user_form: user_form)
    |> assign(current_user: user)
    |> assign(current_password: current_password)
    |> assign(has_password: User.has_password?(user))
  end

  defp generate_qrcode(uri) do
    uri
    |> EQRCode.encode()
    |> EQRCode.svg(width: @qrcode_size)
    |> raw()
  end

  defp format_secret(secret) do
    secret
    |> Base.encode32(padding: false)
    |> String.graphemes()
    |> Enum.map(&maybe_highlight_digit/1)
    |> Enum.chunk_every(4)
    |> Enum.intersperse(" ")
    |> raw()
  end

  defp maybe_highlight_digit(char) do
    case Integer.parse(char) do
      :error -> char
      _ -> ~s(<span class="text-primary-600 dark:text-primary-400">#{char}</span>)
    end
  end
end

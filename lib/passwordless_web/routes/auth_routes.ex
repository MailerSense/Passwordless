defmodule PasswordlessWeb.AuthRoutes do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import PasswordlessWeb.UserAuth

      scope "/auth", PasswordlessWeb do
        pipe_through [:browser]

        # Confirm account
        get "/confirm/:token", UserConfirmationController, :update

        # Sign out
        delete "/sign-out", UserSessionController, :delete

        live_session :auth_public_session, on_mount: [{PasswordlessWeb.User.Hooks, :maybe_assign_user}] do
          # Password reset
          live "/confirm", Auth.ConfirmationInstructionsLive, :new

          # Password reset
          live "/reset-password/:token", Auth.ResetPasswordLive, :edit
        end
      end

      scope "/auth", PasswordlessWeb do
        pipe_through [:browser, :redirect_if_user_is_authenticated]

        live_session :auth_session, on_mount: [{PasswordlessWeb.User.Hooks, :redirect_if_user_is_authenticated}] do
          # Sign in
          live "/sign-in", Auth.SignInLive, :new

          # Register
          live "/sign-up", Auth.RegistrationLive, :new

          # Passwordless
          live "/sign-in/passwordless", Auth.PasswordlessLive, :sign_in

          # Reset password
          live "/reset-password", Auth.ForgotPasswordLive, :new
        end

        # Password
        post "/sign-in", UserSessionController, :create

        # Passwordless
        get "/sign-in/passwordless/complete/:token", UserSessionController, :create_from_token

        # Social
        get "/:provider", UserUeberauthController, :request
        get "/:provider/callback", UserUeberauthController, :callback
      end
    end
  end
end

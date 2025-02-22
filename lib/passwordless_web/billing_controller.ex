defmodule PasswordlessWeb.BillingController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Billing
  alias Passwordless.Billing.Customer
  alias Passwordless.Billing.Subscription
  alias Passwordless.Organizations.Org

  @provider Application.compile_env!(:passwordless, :billing_provider)

  def checkout(conn, %{"plan" => plan}, _user) do
    %Org{} = current_org = Map.fetch!(conn.assigns, :current_org)

    case Billing.get_customer(current_org) do
      %Customer{subscription: %Subscription{} = subscription} ->
        if Subscription.valid?(subscription) do
          conn
          |> put_flash(:error, gettext("There is an existing valid subscription!"))
          |> redirect(to: ~p"/app/billing")
        else
          conn
          |> put_flash(:info, gettext("There is an existing subscription, but it's invalid. Please contact support."))
          |> redirect(to: ~p"/app/billing")
        end

      nil ->
        case @provider.checkout(current_org, plan) do
          {:ok, _customer, session} ->
            redirect(conn, external: @provider.checkout_url(session))

          {:error, reason} ->
            conn
            |> put_flash(:error, gettext("Something went wrong with our payment portal: ") <> inspect(reason))
            |> redirect(to: ~p"/app/billing")
        end
    end
  end
end

defmodule Passwordless.Billing.Providers.Behaviour do
  @moduledoc """
  To be implemented by all billing providers.
  """

  @callback checkout(org :: map(), plan :: map()) :: {:ok, term()} | {:error, term()}
  @callback checkout_url(session :: term()) :: String.t()
  @callback change_plan(customer :: map(), subscription :: map(), plan :: map()) ::
              {:ok, term()} | {:error, term()}
  @callback retrieve_subscription(id :: binary()) :: {:ok, term()} | {:error, term()}
  @callback cancel_subscription(id :: binary()) :: {:ok, term()} | {:error, term()}
  @callback sync_subscription(subscription :: map()) :: {:ok, map()} | {:error, term()}

  defmacro __using__(_) do
    quote do
      @behaviour Passwordless.Billing.Providers.Behaviour

      import Passwordless.Billing.Providers.Behaviour.UrlHelpers
    end
  end

  defmodule UrlHelpers do
    @moduledoc false
    use PasswordlessWeb, :controller

    alias Passwordless.BillingCustomer

    def success_url(%BillingCustomer{id: customer_id}) do
      url(PasswordlessWeb.Endpoint, ~p"/subscribe/success?customer_id=#{customer_id}")
    end

    def cancel_url do
      url(PasswordlessWeb.Endpoint, ~p"/subscribe")
    end
  end
end

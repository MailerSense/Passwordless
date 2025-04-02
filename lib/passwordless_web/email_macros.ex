defmodule PasswordlessWeb.EmailMacros do
  @moduledoc false
  @emails Application.compile_env!(:passwordless, :emails)

  defmacro __using__(_) do
    functions =
      for {kind,
           [
             name: name,
             email: email,
             domain: domain,
             reply_to: reply_to,
             reply_to_name: reply_to_name
           ]} <- @emails do
        quote do
          def unquote(:"#{kind}_email")(opts \\ []) do
            {unsubscribe_url, _opts} = Keyword.pop(opts, :unsubscribe_url)

            new()
            |> from({unquote(name), unquote(email)})
            |> reply_to({unquote(reply_to_name), unquote(reply_to)})
            |> assign(:unsubscribe_url, unsubscribe_url)
          end

          def unquote(:"#{kind}_email_address")(), do: unquote(email)

          def unquote(:"#{kind}_email_domain")(), do: unquote(domain)
        end
      end

    base =
      quote do
        use Phoenix.Swoosh,
          view: PasswordlessWeb.EmailView,
          layout: {PasswordlessWeb.EmailView, :email_layout}
      end

    [base | functions]
  end
end

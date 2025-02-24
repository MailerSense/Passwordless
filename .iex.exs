import SqlFmt.Helpers

alias Passwordless.Accounts
alias Passwordless.Accounts.Notifier
alias Passwordless.Accounts.Query
alias Passwordless.Accounts.User
alias Passwordless.Accounts.UserSeeder
alias Passwordless.Activity
alias Passwordless.Activity.Log
alias Passwordless.Billing.Plans
alias Passwordless.Organizations
alias Passwordless.Organizations.Invitation
alias Passwordless.Organizations.Membership
alias Passwordless.Organizations.Org
alias Passwordless.Repo
alias Phoenix.LiveView

Mix.ensure_application!(:wx)
Mix.ensure_application!(:runtime_tools)

# Don't cut off inspects with "..."
IEx.configure(inspect: [limit: :infinity])
IEx.configure(auto_reload: true)

# Allow copy to clipboard
# eg:
#    iex(1)> Phoenix.Router.routes(PasswordlessWeb.Router) |> Helpers.copy
#    :ok
defmodule Helpers do
  @moduledoc false

  def copy(term) do
    text =
      if is_binary(term) do
        term
      else
        inspect(term, limit: :infinity, pretty: true)
      end

    port = Port.open({:spawn, "pbcopy"}, [])
    true = Port.command(port, text)
    true = Port.close(port)

    :ok
  end
end

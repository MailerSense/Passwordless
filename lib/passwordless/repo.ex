defmodule Passwordless.Repo do
  use Ecto.Repo,
    otp_app: :passwordless,
    adapter: Ecto.Adapters.Postgres

  use Database.RepoExt
  use Database.SoftDelete
  use Database.Multitenant
end

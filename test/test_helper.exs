ExUnit.configure(exclude: [:petal_framework])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Passwordless.Repo, :manual)

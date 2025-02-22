defmodule PasswordlessWeb.Config do
  @moduledoc """
  Config holds env-dependent endpoint config
  """

  @session Application.compile_env!(:passwordless, :session)
  @max_age Keyword.fetch!(@session, :max_age)
  @signing_salt Keyword.fetch!(@session, :signing_salt)
  @encryption_salt Keyword.fetch!(@session, :encryption_salt)

  @session [
    key: "_session_key",
    store: :cookie,
    max_age: div(@max_age, 1000),
    http_only: true,
    signing_salt: @signing_salt,
    encryption_salt: @encryption_salt
  ]

  @corsica [
    allow_credentials: true,
    allow_headers: :all,
    allow_methods: :all,
    max_age: 600
  ]

  def session_options(:prod) do
    Keyword.merge(@session,
      secure: true,
      domain: "livecheck.io",
      same_site: "None"
    )
  end

  def session_options(_) do
    Keyword.merge(@session,
      secure: false,
      same_site: "Lax"
    )
  end

  def corsica_options(:prod) do
    Keyword.put(@corsica, :origins, "https://livecheck.io")
  end

  def corsica_options(_) do
    Keyword.put(@corsica, :origins, "*")
  end
end

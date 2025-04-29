defprotocol Passwordless.Templating.VariableProvider do
  @moduledoc """
  A protocol for providing variables to templates.
  """

  @spec name(t) :: binary()
  def name(value)

  @spec variables(t) :: map()
  def variables(value)
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.App do
  alias Passwordless.App
  alias Passwordless.Repo

  @keys ~w(
    name
  )a
  @settings_keys ~w(
    name
    logo
    website
    display_name
    primary_button_color
    secondary_button_color
  )a

  def name(_), do: "app"

  @doc """
  Provide the app variables.
  """
  def variables(%App{} = app) do
    app = Repo.preload(app, :settings)

    settings_keys =
      app.settings
      |> Map.from_struct()
      |> Map.take(@settings_keys)

    app
    |> Map.from_struct()
    |> Map.take(@keys)
    |> Map.merge(settings_keys)
  end
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.Actor do
  alias Passwordless.Actor
  alias Passwordless.Email
  alias Passwordless.Phone
  alias Passwordless.Repo

  @keys ~w(
    name
    user_id
    language
  )a

  def name(_), do: "user"

  @doc """
  Provide the actor variables.
  """
  def variables(%Actor{} = actor) do
    actor = Repo.preload(actor, [:email, :phone])

    variables =
      Enum.reduce([&add_email/1, &add_phone/1, &add_properties/1], %{}, fn func, acc ->
        Map.merge(acc, func.(actor))
      end)

    actor
    |> Map.from_struct()
    |> Map.take(@keys)
    |> Map.merge(variables)
  end

  # Private

  defp add_email(%Actor{email: %Email{} = email}) do
    %{"email" => email.address}
  end

  defp add_email(%Actor{}), do: %{}

  defp add_phone(%Actor{phone: %Phone{} = phone}) do
    %{"phone" => phone.canonical}
  end

  defp add_phone(%Actor{}), do: %{}

  defp add_properties(%Actor{properties: properties}) when is_map(properties) do
    %{"properties" => properties}
  end

  defp add_properties(%Actor{}), do: %{properties: %{}}
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.Action do
  alias Passwordless.Action

  def name(_), do: "action"

  @doc """
  Provide the action variables.
  """
  def variables(%Action{state: state} = action) do
    %{"name" => Action.readable_name(action), "state" => Atom.to_string(state)}
  end
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.OTP do
  use Gettext, backend: PasswordlessWeb.Gettext

  alias Passwordless.OTP

  def name(_), do: "otp"

  @doc """
  Provide the action variables.
  """
  def variables(%OTP{code: code, expires_at: expires_at} = action) do
    expires_in = DateTime.diff(expires_at, DateTime.utc_now(), :minute)

    %{
      "code" => code,
      "expires_in" => ngettext("1 minute", "%{count} minutes", expires_in)
    }
  end
end

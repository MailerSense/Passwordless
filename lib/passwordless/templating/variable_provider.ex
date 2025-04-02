defprotocol Passwordless.Templating.VariableProvider do
  @spec provide(t) :: map()
  def provide(value)
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.App do
  alias Passwordless.App

  @keys ~w(
    name
    logo
    website
    display_name
    primary_button_color
    secondary_button_color
  )a

  @doc """
  Provide the app variables.
  """
  def provide(%App{} = app) do
    app
    |> Map.from_struct()
    |> Map.take(@keys)
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

  @doc """
  Provide the actor variables.
  """
  def provide(%Actor{} = actor) do
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

  defp add_email(%Actor{email: %Email{} = email} = actor) do
    %{user_email: email.address}
  end

  defp add_email(%Actor{}), do: %{}

  defp add_phone(%Actor{phone: %Phone{} = phone} = actor) do
    %{user_phone: phone.canonical}
  end

  defp add_phone(%Actor{}), do: %{}

  defp add_properties(%Actor{properties: properties} = actor) when is_map(properties) do
    properties
  end

  defp add_properties(%Actor{}), do: %{}
end

defimpl Passwordless.Templating.VariableProvider, for: Passwordless.Action do
  alias Passwordless.Action

  @doc """
  Provide the action variables.
  """
  def provide(%Action{name: name}) do
    %{name: name}
  end
end

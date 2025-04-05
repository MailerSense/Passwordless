defmodule PasswordlessWeb.App.EmailLive.VariableComponent do
  @moduledoc false
  use PasswordlessWeb, :live_component

  alias Passwordless.Action
  alias Passwordless.Actor
  alias Passwordless.App
  alias Passwordless.Email
  alias Passwordless.Phone
  alias Passwordless.Templating.VariableProvider

  @examples [
    %Actor{
      name: "John Doe",
      user_id: "1234567890",
      language: :en,
      properties: %{
        "key1" => "value1",
        "key2" => "value2"
      },
      email: %Email{
        address: "john.doe@megacorp.com"
      },
      phone: %Phone{
        canonical: "+491234567890"
      }
    },
    %Action{
      name: "login"
    }
  ]

  @impl true
  def update(%{app: %App{} = app} = assigns, socket) do
    example =
      Enum.reduce([app | @examples], %{}, fn mod, acc ->
        Map.put(acc, VariableProvider.name(mod), VariableProvider.variables(mod))
      end)

    {:ok, socket |> assign(assigns) |> assign(example: example)}
  end
end

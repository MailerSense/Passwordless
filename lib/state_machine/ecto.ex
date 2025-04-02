defmodule StateMachine.Ecto do
  @moduledoc """
  This addition makes StateMachine fully compatible with Ecto.

  State setter and getter are abstracted in order to provide a way to update a state
  in the middle of transition for a various types of models. With Ecto, we call `change() |> Repo.update`.
  We also wrap every event in transaction, which is rolled back if transition fails to finish.
  This unlocks a lot of beautiful effects. For example, you can enqueue some tasks into db-powered queue in callbacks,
  and if transition failes, those tasks will naturally disappear.

  ### Usage
  To use Ecto, simply pass `repo` param to `defmachine`, you can optionally pass a name of the `Ecto.Type`
  implementation, that will be generated automatically under state machine namespace:


      defmodule EctoMachine do
        use StateMachine

        defmachine field: :state, repo: TestApp.Repo, ecto_type: CustomMod do
          state :resting
          state :working

          # ...
        end
      end

  In your schema you can refer to state type as `EctoMachine.CustomMod`, with `ecto_type` omitted
  it would generate `EctoMachine.StateType`. This custom type is needed to transparently use atoms as states.
  """

  @behaviour StateMachine.State

  @doc """
  This macro defines an Ecto.Type implementation inside of StateMachine namespace.
  The default name is `StateType`, but you can supply any module name.
  The purpose of this is to be able to cast string into atom and back safely,
  validating it against StateMachine defition.
  """
  defmacro define_ecto_type(kind) do
    quote do
      variants = Module.get_attribute(__MODULE__, :"#{unquote(kind)}_names")
      name = Module.get_attribute(__MODULE__, :"#{unquote(kind)}_type")

      unless variants do
        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description: "Ecto type should be declared inside of state machine definition"
      end

      defmodule Module.concat(__MODULE__, name) do
        @variants variants
        StateMachine.Ecto.define_enum(@variants)
      end
    end
  end

  defmacro define_enum(variants) do
    quote do
      @behaviour Ecto.Type

      def type, do: :string

      def cast(value) do
        if s = Enum.find(unquote(variants), &(to_string(&1) == to_string(value))) do
          {:ok, s}
        else
          :error
        end
      end

      def load(value) do
        {:ok, String.to_atom(value)}
      end

      def dump(value) when value in unquote(variants) do
        {:ok, to_string(value)}
      end

      def dump(_), do: :error

      def equal?(s1, s2), do: to_string(s1) == to_string(s2)

      def embed_as(_), do: :self
    end
  end

  @impl true
  def get(ctx) do
    Map.get(ctx.model, ctx.definition.field)
  end

  @impl true
  def set(ctx, state) do
    ctx.model
    |> Ecto.Changeset.change([{ctx.definition.field, state}])
    |> ctx.definition.misc[:repo].update()
    |> case do
      {:ok, model} ->
        %{ctx | model: model}

      {:error, e} ->
        %{ctx | status: :failed, message: {:set_state, e}}
    end
  end
end

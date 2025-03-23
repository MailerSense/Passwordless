defmodule StateMachine.Validation do
  @moduledoc """
  StateMachine supports automatic validation on compile time.
  It makes its best effort to ensure determinism (to some degree).
  It checks that all used states were previously defined.

  TODO: Check unreachable states?
  """

  alias StateMachine.Introspection

  def __after_compile__(env, _) do
    with errors when errors != [] <- validate_all(apply(env.module, :__state_machine__, [])) do
      raise CompileError, file: env.file, description: Enum.join(errors, "\n")
    end
  end

  def validate_all(sm) do
    for {:error, e} <- [
          validate_states_in_transitions(sm),
          validate_transitions_determinism(sm)
        ],
        do: List.flatten(e)
  end

  # TODO: State uniqueness
  # TODO: Empty events

  @doc """
  Validates presense of states used in transitions.
  """
  def validate_states_in_transitions(sm) do
    states = Introspection.all_states(sm)

    errors =
      Enum.reduce(sm.events, [], fn {event_name, event}, acc1 ->
        Enum.reduce(event.transitions, acc1, fn transition, acc2 ->
          transition
          |> Map.take([:to, :from])
          |> Map.values()
          |> Enum.reduce(acc2, fn state, acc3 ->
            if state in states do
              acc3
            else
              ["Undefined state '#{state}' is used in transition on '#{event_name}' event." | acc3]
            end
          end)
        end)
      end)

    if Enum.empty?(errors) do
      {:ok, sm}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Validates that no more than one unguarded transition is originated in every state.
  """
  def validate_transitions_determinism(sm) do
    errors =
      Enum.reduce(sm.events, [], fn {event_name, event}, acc1 ->
        event.transitions
        |> Enum.reduce({[], acc1}, fn transition, {ts, acc2} ->
          cond do
            transition.from in ts ->
              {ts,
               [
                 "Event '#{event_name}' already has an unguarded transition from '#{transition.from}'; additional transition to '#{transition.to}' will never run."
                 | acc2
               ]}

            Enum.empty?(transition.guards) ->
              {[transition.from | ts], acc2}

            true ->
              {ts, acc2}
          end
        end)
        |> elem(1)
      end)

    if Enum.empty?(errors) do
      {:ok, sm}
    else
      {:error, Enum.reverse(errors)}
    end
  end
end

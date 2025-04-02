defmodule StateMachine.Event do
  @moduledoc """
  Event is a container for transitions. It is identified by name (atom) and can contain arbitrary number of transtitions.

  One important thing is that it's disallowed to have more than one unguarded transition from the state, since this
  would introduce a "non-determinism" (or rather just discard the latter transition). We loosely allow guarded transitions
  from the same state, but it doesn't guarantee anything: if guards always return true, we're back to where we were before.
  """

  alias StateMachine.Callback
  alias StateMachine.Context
  alias StateMachine.Event
  alias StateMachine.Guard
  alias StateMachine.Transition

  @type t(model) :: %__MODULE__{
          name: atom,
          schema: module() | nil,
          transitions: list(Transition.t(model)),
          before: list(Callback.t(model)),
          after: list(Callback.t(model)),
          guards: list(Guard.t(model))
        }

  @type callback_pos() :: :before | :after

  @enforce_keys [:name]
  defstruct [
    :name,
    schema: nil,
    transitions: [],
    before: [],
    after: [],
    guards: []
  ]

  @doc """
  Checks if the event is allowed in the current context. First it makes sure that all guards
  of the event return `true`, then it scans transitions for the matching one. Match is determined
  by the source state and passing of all guards as well.
  """
  @spec is_allowed?(Context.t(model), t(model) | atom) :: boolean when model: var
  def is_allowed?(ctx, event) do
    !is_nil(find_transition(ctx, event))
  end

  @doc """
  This is an entry point for transition. By running this function with populated context, event
  and optional payload, you tell state machine to try to move to the next state.
  It returns an updated context.
  """
  @spec trigger(Context.t(model), atom, any) :: Context.t(model) when model: var
  def trigger(ctx, event, payload \\ nil) do
    context = %{ctx | payload: payload, event: event}

    with {_, %Event{} = e} <- {:event, Map.get(context.definition.events, event)},
         {_, %Transition{} = t} <- {:transition, find_transition(context, e)},
         {:ok, p} <- validate_payload(e, payload) do
      Transition.run(%{context | payload: p, transition: t})
    else
      {item, _} -> %{context | status: :failed, error: {item, "Couldn't resolve #{item}"}}
    end
  end

  @doc """
  Private function for running Event callbacks.
  """
  @spec callback(Context.t(model), callback_pos()) :: Context.t(model) when model: var
  def callback(ctx, pos) do
    callbacks = Map.get(ctx.definition.events[ctx.event], pos)
    Callback.apply_chain(ctx, callbacks, :"#{pos}_event")
  end

  # Private

  defp find_transition(ctx, event) do
    if Guard.check(ctx, event) do
      state = ctx.definition.state_getter.(ctx)

      Enum.find(event.transitions, fn transition ->
        transition.from == state && Transition.is_allowed?(ctx, transition)
      end)
    end
  end

  defp validate_payload(%Event{schema: schema}, payload) when is_atom(schema) and not is_nil(schema) do
    apply(schema, :new, [payload])
  end

  defp validate_payload(_event, payload), do: {:ok, payload}
end

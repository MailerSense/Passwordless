defmodule Util.Persistent do
  @moduledoc false

  defmacro defpersistent([{name, value}]) do
    atom = quote(do: {__MODULE__, __ENV__.function})
    function = Macro.var(name, nil)

    quote do
      def unquote(function) do
        case :persistent_term.get(unquote(atom), nil) do
          nil ->
            value = unquote(value)
            :persistent_term.put(unquote(atom), {value})
            value

          {value} ->
            value
        end
      end
    end
  end
end

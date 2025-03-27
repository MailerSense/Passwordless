defmodule Passwordless.Activity.Filter do
  @moduledoc """
  A filter DSL for the activity log.
  """

  import Ecto.Query

  alias Passwordless.Activity.Log

  def apply(query \\ Log, question) do
    is_uuid? =
      case Uniq.UUID.cast(question) do
        {:ok, _} -> true
        _ -> false
      end

    assocs =
      :associations
      |> Log.__schema__()
      |> Enum.reduce([], fn assoc, acc ->
        case Log.__schema__(:type, :"#{assoc}_id") do
          :binary_id -> [assoc | acc]
          _ -> acc
        end
      end)

    query =
      Enum.reduce(assocs, query, fn assoc, query ->
        join_assoc(query, assoc)
      end)

    fields =
      Enum.reduce(assocs, [], fn assoc, acc ->
        case Log.__schema__(:association, assoc) do
          %{queryable: mod} when is_atom(mod) ->
            fields =
              mod
              |> apply(:__schema__, [:fields])
              |> Enum.reduce([], fn field, acc ->
                case apply(mod, :__schema__, [:type, field]) do
                  :string -> [{:ilike, field} | acc]
                  :binary_id -> [{:uuid, field} | acc]
                  UUIDv7 -> [{:uuid, field} | acc]
                  _ -> acc
                end
              end)

            if Enum.empty?(fields),
              do: acc,
              else: [{assoc, fields} | acc]

          _ ->
            acc
        end
      end)

    conditions =
      Enum.reduce(fields, dynamic(false), fn {assoc, fields}, query ->
        Enum.reduce(fields, query, fn
          {:ilike, f}, q ->
            if is_uuid? do
              query
            else
              dynamic([{^assoc, a}], ^q or ilike(field(a, ^f), ^"%#{question}%"))
            end

          {:uuid, f}, q ->
            if is_uuid? do
              dynamic([{^assoc, a}], ^q or field(a, ^f) == ^question)
            else
              query
            end
        end)
      end)

    where(query, ^conditions)
  end

  # Private

  defp join_assoc(query, binding) do
    if has_named_binding?(query, binding),
      do: query,
      else: join(query, :left, [l], assoc(l, ^binding), as: ^binding)
  end
end

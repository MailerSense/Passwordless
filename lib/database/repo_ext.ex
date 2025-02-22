defmodule Database.RepoExt do
  @moduledoc """
  Extend Repo with some useful functions.
  Add this line to your repo:

      use Database.RepoExt
  """

  defmacro __using__(_) do
    quote do
      import Ecto.Query

      @doc """
      Runs the given function inside a transaction.

      This function is a wrapper around `Ecto.Repo.transaction`, with the following differences:

      - It accepts only a lambda of arity 0 or 1 (i.e. it doesn't work with multi).
      - If the lambda returns `:ok | {:ok, result}` the transaction is committed.
      - If the lambda returns `:error | {:error, reason}` the transaction is rolled back.
      - If the lambda returns any other kind of result, an exception is raised, and the transaction is rolled back.
      - The result of `transact` is the value returned by the lambda.

      This function accepts the same options as `Ecto.Repo.transaction/2`.
      """
      @spec transact((-> result) | (module -> result), Keyword.t()) :: result
            when result: :ok | {:ok, any} | :error | {:error, any}
      def transact(fun, opts \\ []) when is_function(fun) do
        transaction_result =
          transaction(
            fn repo ->
              lambda_result =
                case Function.info(fun, :arity) do
                  {:arity, 0} -> fun.()
                  {:arity, 1} -> fun.(repo)
                end

              case lambda_result do
                :ok -> {__MODULE__, :transact, :ok}
                :error -> rollback({__MODULE__, :transact, :error})
                {:ok, result} -> result
                {:error, reason} -> rollback(reason)
              end
            end,
            opts
          )

        with {outcome, {__MODULE__, :transact, outcome}}
             when outcome in [:ok, :error] <- transaction_result,
             do: outcome
      end

      def limit(model_or_query, limit \\ 5) do
        from x in model_or_query, limit: ^limit
      end

      def order(model_or_query, field \\ :id, direction \\ :desc) do
        from x in model_or_query, order_by: [{^direction, ^field}]
      end

      @doc """
      Retrieves the last object in the database given a schema module.
      user = Repo.last(User)
      """
      def last(model_or_query) do
        __MODULE__.one(from(x in model_or_query, order_by: [desc: x.id], limit: 1))
      end

      @doc """
      Retrieves the first object in the database given a schema module.
      comment = Repo.first(Comment)
      """
      def first(model_or_query, preload \\ []) do
        __MODULE__.one(from(x in model_or_query, order_by: [asc: x.id], limit: 1, preload: ^preload))
      end

      @doc """
      Pass in a queryable and this will count how many are in the database as opposed to fetching them
      user_count = Repo.count(User)
      """
      def count(model_or_query) do
        __MODULE__.one(from(p in model_or_query, select: count()))
      end
    end
  end
end

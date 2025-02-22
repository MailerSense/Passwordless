defmodule Passwordless.Activity do
  @moduledoc """
  API for logging account activity across the system.
  """

  alias Passwordless.Accounts.User
  alias Passwordless.Activity.Log
  alias Passwordless.Billing.Customer
  alias Passwordless.Billing.Subscription
  alias Passwordless.Organizations.AuthToken
  alias Passwordless.Organizations.Org
  alias Passwordless.Repo

  @activity "activity"

  def log(domain, action, params) when is_atom(domain) and is_atom(action) and is_map(params) do
    {attrs, preloads} = build(domain, action, params)
    create(attrs, preloads)
  end

  @doc """
  Log an action asynchronously.
  """
  def log_async(domain, action, params \\ %{}) do
    Passwordless.BackgroundTask.run(fn ->
      log(domain, action, params)
    end)
  end

  @doc """
  Get a log entry by ID and user
  """
  def get!(id) when is_binary(id), do: Repo.get!(Log, id)

  @doc """
  Get a log entry by ID and user
  """
  def get_by_user!(%User{} = user, id) when is_binary(id), do: user |> Log.by_user() |> Repo.get!(id)

  @doc """
  Get a log entry by ID and org
  """
  def get_by_org!(%Org{} = org, id) when is_binary(id), do: org |> Log.by_org() |> Repo.get!(id)

  @doc """
  Lists all supported action names.
  """
  def supported_actions do
    Log.supported_actions()
  end

  def topic_for(%Org{} = org), do: "#{@activity}:#{org.id}"

  # Private

  defp create(attrs, preloads) when is_map(attrs) and is_map(preloads) do
    attrs = Map.put_new(attrs, :happened_at, DateTime.utc_now())

    case %Log{}
         |> Log.changeset(attrs)
         |> Repo.insert() do
      {:ok, log} ->
        log = struct!(Log, log |> Map.from_struct() |> Map.merge(preloads))
        PasswordlessWeb.Endpoint.broadcast(topic_name(log), event_name(log), log)
        {:ok, log}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp topic_name(%Log{org_id: org_id}) when is_binary(org_id), do: "#{@activity}:#{org_id}"
  defp topic_name(_), do: @activity

  defp event_name(%Log{domain: domain, action: action}) when is_atom(domain) and is_atom(action) do
    "#{domain}:#{action}"
  end

  @field_mapping [
    {Org, :org, :org_id},
    {User, :user, :user_id},
    {AuthToken, :auth_token, :auth_token_id},
    {User, :target_user, :target_user_id},
    {Customer, :billing_customer, :billing_customer_id},
    {Subscription, :billing_subscription, :billing_subscription_id}
  ]
  @field_mapping_keys Enum.flat_map(@field_mapping, fn {_, field, key} -> [field, key] end)

  defp build(domain, action, params) when is_atom(domain) and is_atom(action) and is_map(params) do
    preloads =
      Enum.reduce(@field_mapping, %{}, fn {module, field, _key}, acc ->
        case params[field] do
          %^module{} = mod -> Map.put(acc, field, mod)
          _ -> acc
        end
      end)

    field_params =
      Enum.reduce(@field_mapping, %{}, fn {module, field, key}, acc ->
        id =
          case params[field] do
            %^module{id: id} -> id
            _ -> params[key]
          end

        Map.put(acc, key, id)
      end)

    metadata = Map.drop(params, @field_mapping_keys ++ [:domain, :action, :metadata])

    attrs =
      Map.merge(field_params, %{
        domain: domain,
        action: action
      })

    attrs = deduce_org_id(attrs)
    attrs = if map_size(metadata) > 0, do: Map.put(attrs, :metadata, metadata), else: attrs

    {attrs, preloads}
  end

  defp deduce_org_id(attrs) when is_map(attrs) do
    case attrs do
      %{org_id: nil, user: %User{current_org: %Org{} = org}} ->
        Map.put(attrs, :org_id, org.id)

      _ ->
        attrs
    end
  end
end

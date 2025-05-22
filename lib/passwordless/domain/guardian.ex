defmodule Passwordless.Domain.Guardian do
  @moduledoc """
  Guards the reputation of an email domain.
  """

  import Ecto.Query

  alias Database.Tenant
  alias Passwordless.App
  alias Passwordless.Domain
  alias Passwordless.Email
  alias Passwordless.EmailEvent
  alias Passwordless.Repo

  @thresholds [
    rejects: 0.01,
    hard_bounces: 0.001,
    soft_bounces: 0.01,
    complaints: 0.001
  ]

  def guard(%App{} = app, %Domain{} = domain, %Email{} = email, %EmailEvent{} = event) do
    case check(event) do
      {:suspend, reason} ->
        with {:ok, opt_out} <- Passwordless.opt_email_out(app, email, reason),
             {:ok, app} <- maybe_suspend_app(app, domain),
             do: {:ok, domain}

      :pass ->
        {:ok, domain}
    end
  end

  def check(%EmailEvent{kind: :bounce, bounce_type: :permanent}), do: {:suspend, "hard bounce"}
  def check(%EmailEvent{kind: :bounce, bounce_type: :transient}), do: {:suspend, "soft bounce"}
  def check(%EmailEvent{kind: :complaint}), do: {:suspend, "complaint"}
  def check(%EmailEvent{kind: :reject}), do: {:suspend, "reject"}
  def check(%EmailEvent{}), do: :pass

  def check_rates(%App{} = app, %Domain{} = domain) do
    loast_statistics(app, domain)
  end

  # Private

  defp maybe_suspend_app(%App{state: :active} = app, %Domain{} = domain) do
    if map_size(loast_statistics(app, domain)) > 0 do
      Passwordless.suspend_app(app)
    else
      {:ok, app}
    end
  end

  @two_weeks 2 |> Timex.Duration.from_weeks() |> Timex.Duration.to_seconds() |> trunc()

  defp loast_statistics(%App{} = app, %Domain{} = domain) do
    time_threshold = DateTime.add(DateTime.utc_now(), @two_weeks, :second)

    query =
      from ee in EmailEvent,
        prefix: ^Tenant.to_prefix(app),
        left_join: em in assoc(ee, :email_message),
        prefix: ^Tenant.to_prefix(app),
        where: em.domain_id == ^domain.id and ee.inserted_at >= ^time_threshold,
        select: %{
          total: count(ee.id),
          hard_bounces: ee.id |> count() |> filter(ee.kind == :bounce and ee.bounce_type == :permanent),
          soft_bounces: ee.id |> count() |> filter(ee.kind == :bounce and ee.bounce_type == :transient),
          complaints: ee.id |> count() |> filter(ee.kind == :complaint),
          rejects: ee.id |> count() |> filter(ee.kind == :reject)
        },
        group_by: em.domain_id

    case_result =
      case Repo.one(query) do
        %{
          total: total,
          hard_bounces: hard_bounces,
          soft_bounces: soft_bounces,
          complaints: complaints,
          rejects: rejects
        } ->
          %{
            hard_bounces: hard_bounces / total,
            soft_bounces: soft_bounces / total,
            complaints: complaints / total,
            rejects: rejects / total
          }

        _ ->
          %{
            hard_bounces: 0,
            soft_bounces: 0,
            complaints: 0,
            rejects: 0
          }
      end

    Enum.filter(case_result, fn {key, val} -> val >= @thresholds[key] end)
  end
end

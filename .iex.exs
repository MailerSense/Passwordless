import SqlFmt.Helpers

alias Passwordless.Accounts
alias Passwordless.Accounts.Notifier
alias Passwordless.Accounts.Query
alias Passwordless.Accounts.User
alias Passwordless.Accounts.UserSeeder
alias Passwordless.Activity
alias Passwordless.Activity.Log
alias Passwordless.Billing.Plans
alias Passwordless.Coordinator
alias Passwordless.Organizations
alias Passwordless.Organizations.Invitation
alias Passwordless.Organizations.Membership
alias Passwordless.Organizations.Org
alias Passwordless.Repo
alias Phoenix.LiveView

Mix.ensure_application!(:wx)
Mix.ensure_application!(:runtime_tools)
Mix.ensure_application!(:passwordless)

# Don't cut off inspects with "..."
IEx.configure(inspect: [limit: :infinity])
IEx.configure(auto_reload: true)

# Allow copy to clipboard
# eg:
#    iex(1)> Phoenix.Router.routes(PasswordlessWeb.Router) |> Helpers.copy
#    :ok
defmodule Helpers do
  @moduledoc false
  alias Passwordless.Scheduler
  alias Passwordless.Scheduler.Constraint

  def copy(term) do
    text =
      if is_binary(term) do
        term
      else
        inspect(term, limit: :infinity, pretty: true)
      end

    port = Port.open({:spawn, "pbcopy"}, [])
    true = Port.command(port, text)
    true = Port.close(port)

    :ok
  end

  def clamp(n, min, max) do
    if n < min, do: min, else: if(n > max, do: max, else: n)
  end

  def filter_first_occurrences_by_id(list) do
    list
    |> Enum.reduce({[], MapSet.new()}, fn item, {acc, seen_ids} ->
      id = item[:id]

      if MapSet.member?(seen_ids, id) do
        {acc, seen_ids}
      else
        {[item | acc], MapSet.put(seen_ids, id)}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def demo_data(checks, sched_start, sched_end, sched_section) do
    schedule_start = trunc(sched_start * 60)
    schedule_end = trunc(sched_end * 60)

    initial_schedules =
      Enum.map(1..checks, fn i ->
        %{
          id: i,
          interval: Enum.random([10, 15, 30, 60, 120, 180]),
          start_time: Enum.random(0..180)
        }
      end)

    constraints =
      0..240
      |> Stream.flat_map(fn minute ->
        initial_schedules
        |> Enum.filter(fn schedule ->
          cond do
            schedule.start_time > minute ->
              false

            schedule.start_time == minute ->
              true

            schedule.start_time < minute ->
              rem(minute - schedule.start_time, schedule.interval) == 0
          end
        end)
        |> Enum.map(fn schedule ->
          %{
            id: schedule.id,
            interval: schedule.interval,
            start_time: minute
          }
        end)
      end)
      |> Stream.filter(fn run -> run.start_time in sched_section end)
      |> filter_first_occurrences_by_id()
      |> Enum.map(fn schedule ->
        %Constraint{
          interval: schedule.interval * 60,
          start_time: schedule.start_time * 60,
          mean_runtime: 1.0 * Enum.random(100..200),
          runtime_variance: 1.0 * 30
        }
      end)

    %{
      checks: checks,
      schedule_start: schedule_start,
      schedule_end: schedule_end,
      constraints: constraints
    }
  end

  def greedy_schedule do
    %{
      constraints: constraints
    } = demo_data(1000, 0, 3 * 60, 0..60)

    example_config = %Scheduler.GreedyConfig{
      interval: 15 * 60,
      mean_runtime: 1.0 * Enum.random(100..200),
      runtime_variance: 1.0 * 30,
      constraints: constraints,
      schedule_window: 60 * 60,
      schedule_start: 1 * 60,
      schedule_end: 16 * 60
    }

    Passwordless.Native.greedy_schedule(example_config)
  end

  def balanced_schedule do
    %{
      checks: checks,
      schedule_start: schedule_start,
      schedule_end: schedule_end,
      constraints: constraints
    } = demo_data(3000, 0, 5 * 60, 60..240)

    pop_size = checks * 5
    elitism_size = round(0.05 * pop_size)

    example_config = %Scheduler.BalancedConfig{
      pop_size: pop_size,
      pool_size: 30,
      constraints: constraints,
      schedule_start: schedule_start,
      schedule_end: schedule_end,
      reschedule_range: 30 * 60,
      elitism_size: elitism_size,
      selection_size: 5_000,
      mutation_rate: 0.15,
      max_generations: 200,
      max_good_runs: 30,
      jitter_mean: 0.0,
      jitter_std_dev: 600.0
    }

    Passwordless.Native.balanced_schedule(example_config)
  end
end

Ecto.Adapters.SQL.query(Repo, ~SQL"REFRESH MATERIALIZED VIEW CONCURRENTLY schedule_statistics;")

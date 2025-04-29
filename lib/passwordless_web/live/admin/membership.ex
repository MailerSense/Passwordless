defmodule PasswordlessWeb.Admin.MembershipLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.Organizations.Membership,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.Organizations.Membership.changeset/3,
      create_changeset: &Passwordless.Organizations.Membership.changeset/3
    ],
    fluid?: true

  import Ecto.Query

  alias Passwordless.Organizations.Membership

  @impl Backpex.LiveResource
  def singular_name, do: "Membership"

  @impl Backpex.LiveResource
  def plural_name, do: "Memberships"

  @impl Backpex.LiveResource
  def fields do
    [
      id: %{
        label: "ID",
        module: Backpex.Fields.Text,
        only: [:show]
      },
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "User",
        prompt: "Please select a user",
        display_field: :full_name,
        select: dynamic([user: u], fragment("concat(?, ' (', ?, ')')", u.name, u.email)),
        options_query: fn query, _assigns ->
          select_merge(query, [user], %{full_name: fragment("concat(?, ' (', ?, ')')", user.name, user.email)})
        end,
        index_editable: true,
        searchable: true,
        live_resource: PasswordlessWeb.Admin.UserLive
      },
      org: %{
        module: Backpex.Fields.BelongsTo,
        label: "Organization",
        prompt: "Please select an organization",
        display_field: :full_name,
        select: dynamic([org: o], fragment("concat(?, ' (', ?, ')')", o.name, o.email)),
        options_query: fn query, _assigns ->
          select_merge(query, [org], %{full_name: fragment("concat(?, ' (', ?, ')')", org.name, org.email)})
        end,
        index_editable: true,
        searchable: true,
        live_resource: PasswordlessWeb.Admin.OrgLive
      },
      role: %{
        module: Backpex.Fields.Select,
        label: "Role",
        options: fn _assigns -> Enum.map(Membership.roles(), &{String.capitalize(Atom.to_string(&1)), &1}) end,
        index_editable: true
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Created At",
        only: [:index, :show],
        format: "%d %b %Y, %H:%M"
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At",
        only: [:show],
        format: "%d %b %Y, %H:%M"
      }
    ]
  end

  @impl Backpex.LiveResource
  def metrics do
    [
      owners: %{
        module: Backpex.Metrics.Value,
        label: "Owners",
        class: "w-full lg:w-1/5",
        select: dynamic([m], m.id |> count() |> filter(m.role == :owner)),
        format: &Integer.to_string/1
      },
      admins: %{
        module: Backpex.Metrics.Value,
        label: "Admins",
        class: "w-full lg:w-1/5",
        select: dynamic([m], m.id |> count() |> filter(m.role == :admin)),
        format: &Integer.to_string/1
      },
      manager: %{
        module: Backpex.Metrics.Value,
        label: "Managers",
        class: "w-full lg:w-1/5",
        select: dynamic([m], m.id |> count() |> filter(m.role == :manager)),
        format: &Integer.to_string/1
      },
      member: %{
        module: Backpex.Metrics.Value,
        label: "Members",
        class: "w-full lg:w-1/5",
        select: dynamic([m], m.id |> count() |> filter(m.role == :member)),
        format: &Integer.to_string/1
      },
      billing: %{
        module: Backpex.Metrics.Value,
        label: "Billing",
        class: "w-full lg:w-1/5",
        select: dynamic([m], m.id |> count() |> filter(m.role == :billing)),
        format: &Integer.to_string/1
      }
    ]
  end
end

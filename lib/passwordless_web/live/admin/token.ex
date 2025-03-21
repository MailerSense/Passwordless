defmodule PasswordlessWeb.Admin.TokenLive do
  @moduledoc false
  use Backpex.LiveResource,
    layout: {PasswordlessWeb.Layouts, :admin},
    adapter_config: [
      schema: Passwordless.Accounts.Token,
      repo: Passwordless.Repo,
      update_changeset: &Passwordless.Accounts.Token.edit_changeset/3,
      create_changeset: &Passwordless.Accounts.Token.edit_changeset/3
    ],
    pubsub: [
      name: Passwordless.PubSub,
      topic: "tokens",
      event_prefix: "token_"
    ],
    fluid?: true

  import Ecto.Query

  alias Passwordless.Accounts.Token

  @impl Backpex.LiveResource
  def singular_name, do: "Token"

  @impl Backpex.LiveResource
  def plural_name, do: "Tokens"

  @impl Backpex.LiveResource
  def fields do
    [
      id: %{
        label: "ID",
        module: Backpex.Fields.Text,
        only: [:show]
      },
      email: %{
        label: "Email",
        module: Backpex.Fields.Text,
        searchable: false,
        only: [:show, :edit, :new]
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
        searchable: true,
        live_resource: PasswordlessWeb.Admin.UserLive,
        index_editable: true
      },
      name: %{
        label: "Expires in",
        module: Backpex.Fields.Text,
        select: dynamic([token: t], t),
        render: fn assigns ->
          ~H"""
          <p class="min-w-48">{Token.readable_expiry_time(@value)}</p>
          """
        end,
        sortable: false,
        searchable: false,
        only: [:index, :show]
      },
      context: %{
        label: "Context",
        module: Backpex.Fields.Select,
        options: fn _assigns -> Enum.map(Token.contexts(), &{Phoenix.Naming.humanize(Atom.to_string(&1)), &1}) end,
        sortable: true,
        searchable: true,
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
        only: [:index, :show],
        format: "%d %b %Y, %H:%M"
      }
    ]
  end

  @impl Backpex.LiveResource
  def metrics do
    [
      total: %{
        module: Backpex.Metrics.Value,
        label: "Total tokens",
        class: "w-full lg:w-1/3",
        select: dynamic([t], count(t.id)),
        format: &Integer.to_string/1
      },
      session: %{
        module: Backpex.Metrics.Value,
        label: "Session tokens",
        class: "w-full lg:w-1/3",
        select: dynamic([t], t.id |> count() |> filter(t.context == :session)),
        format: &Integer.to_string/1
      },
      inactive: %{
        module: Backpex.Metrics.Value,
        label: "Other tokens",
        class: "w-full lg:w-1/3",
        select: dynamic([t], t.id |> count() |> filter(t.context != :session)),
        format: &Integer.to_string/1
      }
    ]
  end
end

defmodule PasswordlessWeb.Knowledge.PricingLive do
  @moduledoc """
  Allows for sending bulk emails to a list of recipients.
  """
  use PasswordlessWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: gettext("Pricing"), pricing: pricing())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_user={@current_user} current_page={:pricing} current_section={:knowledge}>
      <div class="flex flex-col gap-6">
        <.form_header title={gettext("Pricing")} no_margin />
        <.p>
          Following tables show the pricing for different services. The baseline plans are dependent on the number of monthly active users (MAU). You are also charged for the communication services if you exceed the allotted free tiers.
        </.p>
        <.simple_table
          :for={item <- @pricing}
          items={item.items}
          count={Enum.count(item.items)}
          title={item.name}
        >
          <:if_empty>
            {gettext("No %{models} found", models: gettext("billing items"))}
          </:if_empty>
          <:col field={:name} />
          <:col field={:price} />
          <:col field={:description} />
          <:col :let={iitem} field={:kind}>
            <.badge
              size="sm"
              label={Phoenix.Naming.humanize(iitem.kind)}
              color={random_color(iitem.kind)}
            />
          </:col>

          <:col actions></:col>
          <:actions :let={item}>
            <.icon_button
              size="sm"
              icon="custom-edit"
              color="light"
              title={gettext("Edit")}
              link_type="live_patch"
            />
          </:actions>
        </.simple_table>
      </div>
    </.layout>
    """
  end

  defp pricing do
    [
      %{
        id: Uniq.UUID.uuid7(),
        name: gettext("Monthly active users"),
        items: [
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Free"),
            kind: :free_tier,
            price: Money.new(0),
            description: gettext("up to 5,000 MAU / month")
          },
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Essential"),
            kind: :flat_monthly_fee,
            price: Money.parse!("49.99"),
            description: gettext("up to 50,000 MAU / month")
          }
        ]
      },
      %{
        id: Uniq.UUID.uuid7(),
        name: gettext("Email messages"),
        items: [
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Free"),
            kind: :free_tier,
            price: Money.new(0),
            description: gettext("up to 5,000 emails / month")
          },
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Outbound"),
            kind: :pay_as_you_go,
            price: Money.parse!("1.0"),
            description: gettext("per 1,000 emails")
          }
        ]
      }
    ]
  end
end

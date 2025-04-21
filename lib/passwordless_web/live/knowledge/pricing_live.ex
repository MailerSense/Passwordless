defmodule PasswordlessWeb.Knowledge.PricingLive do
  @moduledoc """
  Allows for sending bulk emails to a list of recipients.
  """
  use PasswordlessWeb, :live_view

  @page_mapping [
    free: :pricing_free,
    essential: :pricing_pro,
    enterprise: :pricing_enterprise
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: gettext("Pricing"),
       pricing: pricing(),
       menu_items: menu_items(),
       current_page: Keyword.fetch!(@page_mapping, socket.assigns.live_action)
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout
      current_user={@current_user}
      current_page={:pricing}
      current_section={:knowledge}
      current_subpage={@current_page}
      padded={false}
    >
      <.tabbed_layout current_page={@current_page} menu_items={@menu_items} inner_class="p-6">
        <div class="flex flex-col gap-6">
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
            <:col field={:service} />
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
      </.tabbed_layout>
    </.layout>
    """
  end

  defp menu_items do
    PasswordlessWeb.Menus.build_menu([
      :pricing_free,
      :pricing_pro,
      :pricing_enterprise
    ])
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
            service: gettext("up to 5,000 MAU / month")
          },
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Essential"),
            kind: :flat_monthly_fee,
            price: Money.parse!("49.99"),
            service: gettext("up to 50,000 MAU / month")
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
            service: gettext("up to 5,000 emails / month")
          },
          %{
            id: Uniq.UUID.uuid7(),
            name: gettext("Outbound"),
            kind: :pay_as_you_go,
            price: Money.parse!("1.0"),
            service: gettext("per 1,000 emails")
          }
        ]
      }
    ]
  end
end

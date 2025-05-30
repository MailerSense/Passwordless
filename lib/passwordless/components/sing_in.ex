defmodule Passwordless.Components.SingIn do
  @moduledoc """
  A sign in component configuration.
  """

  use Passwordless.Schema, prefix: "magic_link"

  alias Passwordless.App
  alias Passwordless.EmailTemplate

  @behaviors ~w(authenticate click short_code)a
  @fingerprint_factors ~w(device_id ip_address user_agent)a

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :enabled,
      :expires,
      :resend,
      :sender,
      :sender_name,
      :behavior,
      :fingerprint_device,
      :fingerprint_factors,
      :redirect_urls,
      :inserted_at,
      :updated_at
    ]
  }
  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id]
  }
  schema "magic_link_authenticators" do
    field :enabled, :boolean, default: true
    field :expires, :integer, default: 3
    field :resend, :integer, default: 30
    field :sender, :string
    field :sender_name, :string
    field :behavior, Ecto.Enum, values: @behaviors, default: :authenticate
    field :fingerprint_device, :boolean, default: false
    field :fingerprint_factors, {:array, Ecto.Enum}, values: @fingerprint_factors, default: @fingerprint_factors

    embeds_many :redirect_urls, RedirectURL, on_replace: :delete, primary_key: false do
      @derive Jason.Encoder

      field :url, :string, primary_key: true
    end

    belongs_to :app, App
    belongs_to :email_template, EmailTemplate

    timestamps()
  end
end

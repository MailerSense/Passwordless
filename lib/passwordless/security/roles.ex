defmodule Passwordless.Security.Roles do
  @moduledoc """
  Definition of roles a user can have in an organization.
  """

  def org_roles, do: [:owner, :admin, :manager, :member, :billing]

  def org_role_descriptions,
    do: [
      owner: {"Has full access to everything", "rose"},
      admin: {"Has admin access to everything", "fuchsia"},
      manager: {"Has access to most settings", "purple"},
      member: {"Is a regular member", "indigo"},
      billing: {"Has access to billing settings", "cyan"}
    ]

  def auth_token_scopes, do: [:sync]

  def auth_token_descriptions, do: [sync: "Synchronize checks via CLI"]

  def topic_kind_descriptions,
    do: [
      public: "Visible to all contacts",
      private: "Visible only to contacts who are subscribed",
      obligatory: "Required for all contacts"
    ]
end

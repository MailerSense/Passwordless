# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Passwordless.Repo.insert!(%Passwordless.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Database.Multitenant
alias Passwordless.Accounts.Token
alias Passwordless.Accounts.TOTP
alias Passwordless.Accounts.User
alias Passwordless.Accounts.UserSeeder
alias Passwordless.Activity.Log
alias Passwordless.Organizations.Invitation
alias Passwordless.Organizations.Membership
alias Passwordless.Organizations.Org
alias Passwordless.Organizations.OrgSeeder

if Mix.env() == :dev do
  Passwordless.Repo.delete_all(Log)
  Passwordless.Repo.delete_all(TOTP)
  Passwordless.Repo.delete_all(Invitation)
  Passwordless.Repo.delete_all(Membership)
  Passwordless.Repo.delete_all(Org)
  Passwordless.Repo.delete_all(Token)
  Passwordless.Repo.delete_all(User)

  Enum.each(Multitenant.all(), &Multitenant.drop_schema/1)
  admin = UserSeeder.admin()

  normal_user =
    UserSeeder.normal_user(%{
      email: "marcin.praski@gmail.com",
      name: "Sarah Cunningham",
      password: "Qwerty1234!",
      confirmed_at: DateTime.utc_now()
    })

  org = OrgSeeder.root_org_local(admin)

  Passwordless.Organizations.create_invitation(org, %{email: normal_user.email})
end

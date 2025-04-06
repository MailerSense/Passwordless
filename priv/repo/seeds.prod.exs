alias Database.Tenant
alias Passwordless.Accounts.UserSeeder
alias Passwordless.Organizations
alias Passwordless.Organizations.OrgSeeder

Enum.each(Tenant.all(), &Tenant.drop_schema/1)

admin = UserSeeder.admin()

normal_user =
  UserSeeder.normal_user(%{
    email: "marcin.praski@gmail.com",
    name: "Marcin Praski",
    password: "Qwerty1234!",
    confirmed_at: DateTime.utc_now()
  })

org = OrgSeeder.root_org(admin)

Organizations.create_invitation(org, %{email: normal_user.email})

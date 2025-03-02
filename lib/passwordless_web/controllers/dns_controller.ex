defmodule PasswordlessWeb.DNSController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User
  alias Passwordless.App

  NimbleCSV.define(DNSDumper, separator: ",", escape: "\"")

  def download(conn, _params, %User{current_app: %App{} = app}) do
    domain = Passwordless.get_domain!(app)
    records = Passwordless.list_domain_record(domain)

    header = ["Name", "Kind", "Value"]

    rows =
      Enum.map(records, fn record ->
        [record.name, record.kind, record.value]
      end)

    data =
      [header | rows]
      |> DNSDumper.dump_to_iodata()
      |> IO.iodata_to_binary()

    send_download(conn, {:binary, data},
      filename: "Records for #{domain.name}.csv",
      content_type: "text/csv"
    )
  end
end

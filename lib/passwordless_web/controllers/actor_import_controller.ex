defmodule PasswordlessWeb.ActorImportController do
  use PasswordlessWeb, :authenticated_controller

  alias Passwordless.Accounts.User
  alias Passwordless.App

  NimbleCSV.define(ActorTemplateDumper, separator: ",", escape: "\"")

  def download_csv(conn, _params, %User{current_app: %App{} = app}) do
    header = [
      "Name",
      "UserID",
      "State",
      "Language",
      "Properties",
      "Email",
      "Email 2",
      "Phone",
      "Phone 2"
    ]

    rows = [
      [
        "John Doe",
        Uniq.UUID.uuid4(),
        "active",
        "en",
        "property1=value1;property2=value2",
        "john.doe@gmail.com",
        "second-email@protonmain.com",
        "+491234567890",
        "+491234567891"
      ]
    ]

    data =
      [header | rows]
      |> ActorTemplateDumper.dump_to_iodata()
      |> IO.iodata_to_binary()

    send_download(conn, {:binary, data},
      filename: "User Import [Template].csv",
      content_type: "text/csv"
    )
  end
end

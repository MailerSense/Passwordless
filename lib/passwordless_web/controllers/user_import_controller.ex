defmodule PasswordlessWeb.UserImportController do
  use PasswordlessWeb, :authenticated_controller

  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias Passwordless.Accounts.User
  alias Passwordless.App

  NimbleCSV.define(UserTemplateDumper, separator: ",", escape: "\"")

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
        "john.doe@company.com",
        "second-email@protonmain.com",
        "+491234567890",
        "+491234567891"
      ]
    ]

    data =
      [header | rows]
      |> UserTemplateDumper.dump_to_iodata()
      |> IO.iodata_to_binary()

    send_download(conn, {:binary, data},
      filename: "User Import [Template].csv",
      content_type: "text/csv"
    )
  end

  def download_excel(conn, _params, %User{current_app: %App{} = app}) do
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
        "john.doe@company.com",
        "second-email@protonmain.com",
        "+491234567890",
        "+491234567891"
      ]
    ]

    sheet = %Sheet{
      name: "Users",
      rows: [Enum.map(header, &[&1, bold: true]) | rows]
    }

    {:ok, {name, data}} =
      Elixlsx.write_to_memory(%Workbook{sheets: [sheet]}, "User Import [Template].xlsx")

    send_download(conn, {:binary, data},
      filename: to_string(name),
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
  end
end

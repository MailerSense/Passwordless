defmodule PasswordlessWeb.Plugs.MinifyHTML do
  @moduledoc """
  The `PlugMinifyHtml` plug takes care of minifying
  the response body when the response content type is text/html.
  """

  def minify_html(%Plug.Conn{} = conn, _opts) do
    Plug.Conn.register_before_send(conn, fn conn ->
      case List.keyfind(conn.resp_headers, "content-type", 0) do
        {_, "text/html" <> _} ->
          {:ok, document} = Floki.parse_document(conn.resp_body)

          body =
            document
            |> Floki.filter_out(:comment)
            |> Floki.raw_html(pretty: false)

          %Plug.Conn{conn | resp_body: body}

        _ ->
          conn
      end
    end)
  end
end

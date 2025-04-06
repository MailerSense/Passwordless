defmodule PasswordlessWeb.Layouts do
  @moduledoc false
  use PasswordlessWeb, :html

  require Logger

  embed_templates "layouts/*"

  def app_name, do: Passwordless.config(:app_name)

  def title(%Plug.Conn{assigns: %{reason: %Phoenix.Router.NoRouteError{plug_status: plug_status}}})
      when is_integer(plug_status),
      do: "#{plug_status} #{Plug.Conn.Status.reason_phrase(plug_status)}"

  def title(%Plug.Conn{assigns: %{page_title: page_title}}), do: page_title

  def title(%Plug.Conn{}) do
    app_name()
  end

  def canonical_url(%Plug.Conn{} = conn) do
    PasswordlessWeb.Router.Helpers.url(conn) <> conn.request_path
  end

  def current_page_url(%Plug.Conn{request_path: request_path}), do: PasswordlessWeb.Endpoint.url() <> request_path

  def current_page_url(_conn), do: PasswordlessWeb.Endpoint.url()

  def home_page?(%Plug.Conn{request_path: request_path}) do
    URI.parse(request_path).path == "/"
  end

  def public_page?(%Plug.Conn{request_path: request_path}) do
    stripped_path = URI.parse(request_path).path

    public_pages =
      [
        ~p"/"
      ]
      |> Enum.map(&URI.parse(&1).path)
      |> Enum.reject(&(&1 == "/"))

    stripped_path == "/" or Enum.any?(public_pages, &String.starts_with?(stripped_path, &1))
  end

  def admin_page?(%Plug.Conn{request_path: request_path}) do
    String.starts_with?(URI.parse(request_path).path, "/admin")
  end
end

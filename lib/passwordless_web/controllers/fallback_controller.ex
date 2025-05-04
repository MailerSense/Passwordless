defmodule PasswordlessWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use PasswordlessWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: PasswordlessWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, [_ | _] = list}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: PasswordlessWeb.ChangesetJSON)
    |> render(:error, changeset: Enum.map(list, &to_string/1))
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON)
    |> render(:"401")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON)
    |> render(:"403")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :too_many_requests}) do
    conn
    |> put_status(:too_many_requests)
    |> put_view(html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON)
    |> render(:"429")
  end

  def call(conn, {:error, :unprocessable_entity}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(html: PasswordlessWeb.ErrorHTML, json: PasswordlessWeb.ErrorJSON)
    |> render(:"422")
  end

  def call(conn, {:error, reason}) when is_atom(reason) or is_binary(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: PasswordlessWeb.ErrorReasonJSON)
    |> render(:error, reason: reason)
  end
end

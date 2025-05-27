defmodule Passwordless.FileUploads do
  @moduledoc """
  Centralizes file upload functionalities.
  """

  @adapter :passwordless
           |> Application.compile_env!(:file_uploads)
           |> Keyword.fetch!(:adapter)

  def prepare(opts \\ []) do
    if Passwordless.config(:env) == :prod do
      Keyword.put(opts, :external, &@adapter.presign_upload/2)
    else
      opts
    end
  end

  defdelegate consume_uploaded_entries(socket, entry), to: @adapter
end

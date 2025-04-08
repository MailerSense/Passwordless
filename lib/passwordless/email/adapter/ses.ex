defmodule Passwordless.Email.Adapter.SES do
  @moduledoc """
  Sends emails via Amazon SES, with each request authenticated using
  temporary or long-term credentials of the organization provider.
  """

  use Swoosh.Adapter, required_config: []

  alias Passwordless.Domain
  alias Swoosh.Adapters.SMTP.Helpers, as: SMTPHelper
  alias Swoosh.Email

  @impl true
  def deliver(%Email{} = email, config \\ []) do
    case AWS.SES.send_raw_email(AWS.Session.get_client!(), build_request(email, config)) do
      {:ok, %{"MessageId" => message_id}, _raw} ->
        {:ok, %{id: message_id}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Private

  defp build_request(%Email{} = email, config) do
    %{}
    |> prepare_body(email, config)
    |> prepare_source(email)
    |> prepare_source_arn(email)
    |> prepare_from_arn(email)
    |> prepare_destination(email)
    |> prepare_return_path_arn(email)
  end

  defp prepare_body(request, %Email{} = email, config) do
    data =
      email
      |> SMTPHelper.body([{:keep_bcc, true} | config])
      |> Base.encode64()
      |> URI.encode()

    Map.put(request, "RawMessage", %{"Data" => data})
  end

  defp prepare_destination(request, %Email{to: [{_name, address}]}) when is_binary(address) do
    Map.put(request, "Destinations", [address])
  end

  defp prepare_destination(request, %Email{}), do: request

  defp prepare_source(request, %Email{provider_options: %{domain: %Domain{} = domain}}) do
    Map.put(request, "Source", domain.name)
  end

  defp prepare_source(request, %Email{}), do: request

  defp prepare_source_arn(request, %Email{provider_options: %{domain: %Domain{} = domain}}) do
    Map.put(
      request,
      "SourceArn",
      Domain.arn(domain, Passwordless.config([:aws_current, :region]), Passwordless.config([:aws_current, :account]))
    )
  end

  defp prepare_source_arn(request, %Email{}), do: request

  defp prepare_from_arn(request, %Email{provider_options: %{domain: %Domain{} = domain}}) do
    Map.put(
      request,
      "FromArn",
      Domain.arn(domain, Passwordless.config([:aws_current, :region]), Passwordless.config([:aws_current, :account]))
    )
  end

  defp prepare_from_arn(request, %Email{}), do: request

  defp prepare_return_path_arn(request, %Email{provider_options: %{domain: %Domain{} = domain}}) do
    Map.put(
      request,
      "ReturnPathArn",
      Domain.arn(domain, Passwordless.config([:aws_current, :region]), Passwordless.config([:aws_current, :account]))
    )
  end

  defp prepare_return_path_arn(request, %Email{}), do: request
end

defmodule Util.Email do
  @moduledoc """
  Validate email addresses.
  """

  alias EmailChecker.Tools
  alias Util.DomainBlocklist

  @validators Application.compile_env(:passwordless, :email_validators, [
                :plus,
                :format,
                :burner,
                :domain,
                :blocked_domain,
                :common_catch_all,
                :common_provider_typos
              ])

  @doc """
  Check if an email address is valid.
  """
  def valid?(email, validators \\ @validators) do
    case validate(email, validators) do
      :ok -> true
      {:error, _, _} -> false
    end
  end

  @doc """
  Validate an email address.
  """
  def validate(email, validators \\ @validators)

  def validate(email, validators) when is_binary(email) do
    email = String.trim(String.downcase(email))

    Enum.reduce_while(Keyword.take(checks(), validators), :ok, fn {key, {check, message}}, acc ->
      if check.(email),
        do: {:cont, acc},
        else: {:halt, {:error, key, message}}
    end)
  end

  def validate(_, _), do: {:error, :missing, "is missing"}

  @doc """
  Validate an email address and return the result and a list of validations.
  """
  def validate_full(email, validators \\ @validators)

  def validate_full(email, validators) when is_binary(email) do
    email = String.trim(String.downcase(email))

    result =
      Enum.reduce_while(Keyword.take(checks(), validators), [], fn {key, {check, message}}, acc ->
        if check.(email),
          do: {:cont, [{key, true} | acc]},
          else: {:halt, {:error, key, message, [{key, false} | acc]}}
      end)

    case result do
      [_ | _] = acc -> {:ok, acc}
      error -> error
    end
  end

  def validate_full(_, _), do: {:error, :missing, "is missing", []}

  @doc """
  Get a list of available validations.
  """
  def validations, do: Keyword.keys(checks())

  @doc """
  Normalize an email address by removing the plus sign and everything after it.
  """
  def normalize(email) when is_binary(email) do
    with true <- String.contains?(email, "+"),
         %{"domain" => domain} when is_binary(domain) <- Regex.named_captures(Tools.email_regex(), email) do
      name = String.replace_suffix(email, "@#{domain}", "")

      name =
        case String.split(name, "+", parts: 2) do
          [name] -> name
          [name, _] -> name
          _ -> name
        end

      "#{name}@#{domain}"
    else
      _ -> email
    end
  end

  # Private

  defp checks do
    [
      {:plus, {&check_plus/1, "contains plus (+) symbol"}},
      {:format, {&check_format/1, "is invalid"}},
      {:burner, {&check_burner/1, "is a burner email"}},
      {:domain, {&check_domain/1, "is an invalid domain"}},
      {:blocked_domain, {&check_blocked_domain/1, "is likely a spam domain"}},
      {:common_catch_all, {&check_common_catch_all/1, "is a likely catch-all address"}},
      {:common_provider_typos, {&check_common_provider_typos/1, "likely contains a typo"}},
      {:dns, {&check_dns/1, "has no MX or A/AAAA records"}}
    ]
  end

  defp check_plus(email) when is_binary(email) do
    not String.contains?(email, "+")
  end

  defp check_format(email) when is_binary(email) do
    EmailChecker.Check.Format.valid?(email)
  end

  defp check_burner(email) when is_binary(email) do
    not Burnex.is_burner?(email)
  end

  defp check_domain(email) when is_binary(email) do
    with %{"domain" => domain} when is_binary(domain) <- Regex.named_captures(Tools.email_regex(), email),
         {:ok, _} <- Domainatrex.parse(domain) do
      true
    else
      _ -> false
    end
  end

  defp check_blocked_domain(email) when is_binary(email) do
    case Regex.named_captures(Tools.email_regex(), email) do
      %{"domain" => domain} when is_binary(domain) -> not DomainBlocklist.blocked?(domain)
      _ -> true
    end
  end

  @catch_all_names ~w(
    abuse
    admin
    mailer-daemon
    noreply
    no-reply
    postmaster
    root
    security
    support
    sysadmin
    webmaster
    billing
    jobs
    careers
    privacy
    terms
    legal
    compliance
    dmarc
    newsletter
    orders
    bookings
    submissions
    infosec
    adminoffice
    customercare
    account
    feedback
    inquiries
    press
    media
    communications
    partnerships
    updates
    events
    publicrelations
    membership
  )

  defp check_common_catch_all(email) when is_binary(email) do
    case String.split(email, "@", parts: 2) do
      [name, _] when is_binary(name) and name not in @catch_all_names -> true
      _ -> false
    end
  end

  @common_providers ~w(
    gmail
    yahoo
    hotmail
    outlook
    aol
    icloud
    yandex
    protonmail
  )

  defp check_common_provider_typos(email) when is_binary(email) do
    with %{"domain" => domain} when is_binary(domain) <- Regex.named_captures(Tools.email_regex(), email),
         {:ok, %{domain: provider}} when is_binary(provider) <- Domainatrex.parse(domain) do
      not Enum.any?(@common_providers, fn candidate ->
        distance = String.jaro_distance(provider, candidate)
        distance < 1.0 and distance > 0.9
      end)
    else
      _ -> false
    end
  end

  defp check_dns(email) when is_binary(email) do
    case Regex.named_captures(Tools.email_regex(), email) do
      %{"domain" => domain} when is_binary(domain) ->
        Enum.reduce_while([:mx, :a, :aaaa], false, fn record_type, acc ->
          case Util.DNS.resolve(domain, record_type) do
            [_ | _] -> {:halt, true}
            {:error, :nxdomain} -> {:halt, false}
            _ -> {:cont, acc}
          end
        end)

      _ ->
        false
    end
  end
end

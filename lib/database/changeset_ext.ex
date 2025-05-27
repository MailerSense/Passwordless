defmodule Database.ChangesetExt do
  @moduledoc """
  Provides common changeset extensions.
  """

  import Ecto.Changeset

  alias Crontab.CronExpression.Parser, as: CronParser
  alias Util.DomainBlocklist

  @redacted "-"
  @sensitive_keys ~w(
    name
    first_name
    last_name
    email
    phone
    address
    city
    state
    zip
    password
    password_confirmation
    current_password
    new_password
    new_password_confirmation
  )a
  @sensitive_keys_s Enum.map(@sensitive_keys, &Atom.to_string/1)

  @doc """
  Trims the whitespace off both ends of the string.
  "  John Doe " -> "John Doe"
  """
  def ensure_trimmed(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    update_change(changeset, field, &trim/1)
  end

  def ensure_trimmed(%Ecto.Changeset{} = changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      update_change(cs, field, &trim/1)
    end)
  end

  @doc """
  Ensures the value is lowercase.
  """
  def ensure_lowercase(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    update_change(changeset, field, &downcase/1)
  end

  def ensure_lowercase(%Ecto.Changeset{} = changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      update_change(cs, field, &downcase/1)
    end)
  end

  @doc """
  Ensures the code is formatted.
  """
  def ensure_code_formatted(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    update_change(changeset, field, fn code ->
      case Code.format_string!(code) do
        [] -> ""
        formatted_content -> IO.iodata_to_binary([formatted_content, ?\n])
      end
    end)
  end

  @doc """
  Ensures the email is normalized.
  """
  def ensure_email_normalized(%Ecto.Changeset{} = changeset, field \\ :email) when is_atom(field) do
    update_change(changeset, field, &Util.Email.normalize/1)
  end

  @doc """
  Validates an email address by ensuring it is trimmed, has a valid format,
  corresponds to a valid MX record, is not a burner email, and is less than 320 characters.
  """
  def validate_email(%Ecto.Changeset{} = changeset, field \\ :email, opts \\ []) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_change(field, fn ^field, email ->
      email =
        case Keyword.get(opts, :suffix) do
          suffix when is_binary(suffix) -> "#{email}@#{suffix}"
          _ -> email
        end

      case Util.Email.validate(email) do
        :ok -> []
        {:error, _key, message} -> [{field, message}]
      end
    end)
  end

  @doc """
  Validates an email address by ensuring it is trimmed, has a valid format,
  is not a burner email, and is less than 320 characters.
  """
  def validate_email_format(%Ecto.Changeset{} = changeset, field \\ :email, opts \\ []) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_change(field, fn ^field, email ->
      email =
        case Keyword.get(opts, :suffix) do
          suffix when is_binary(suffix) -> "#{email}@#{suffix}"
          _ -> email
        end

      case Util.Email.validate(email, [:format, :domain, :burner]) do
        :ok -> []
        {:error, _key, message} -> [{field, message}]
      end
    end)
  end

  @domain_regex ~r/^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,8}$/

  @doc """
  Validates a domain name by ensuring it is trimmed, is lowercase, has a valid format and TLD.
  """
  def validate_domain(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_format(field, @domain_regex, message: "is not a valid domain name")
    |> validate_change(field, fn ^field, domain ->
      case Domainatrex.parse(domain) do
        {:ok, _} -> []
        {:error, _} -> [{field, "is not a valid tld"}]
      end
    end)
    |> validate_change(field, fn ^field, domain ->
      if DomainBlocklist.blocked?(domain),
        do: [{field, "belongs to a known blocklist"}],
        else: []
    end)
  end

  @doc """
  Validates a domain name by ensuring it is trimmed, is lowercase, has a valid format and TLD and is an actual subdomain.
  """
  def validate_subdomain(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> validate_domain(field)
    |> validate_change(field, fn ^field, domain ->
      case Domainatrex.parse(domain) do
        {:ok, %{domain: domain, subdomain: "", tld: tld}}
        when is_binary(domain) and is_binary(tld) ->
          [{field, "is not a subdomain"}]

        _ ->
          []
      end
    end)
  end

  @doc """
  Validates a URL by ensuring it is trimmed, is lowercase, has a valid format and scheme.
  """
  def validate_url(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_length(field, min: 1, max: 1024)
    |> validate_change(field, fn ^field, url ->
      case URI.parse(url) do
        %URI{scheme: scheme} when not is_nil(scheme) and scheme not in ["http", "https"] ->
          [{field, "is missing a scheme (e.g. https)"}]

        %URI{host: nil} ->
          [{field, "is missing a host (e.g. example.com)"}]

        %URI{} ->
          []
      end
    end)
  end

  @doc """
  Validates an IP address by ensuring it is trimmed, is lowercase, has a valid format and is a public IP.
  """
  def validate_ip_address(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_change(field, fn ^field, value ->
      with {:ok, ip_address} <- InetCidr.parse_address(value), true <- public_ip?(ip_address) do
        []
      else
        _ -> [{field, "is invalid"}]
      end
    end)
  end

  @doc """
  Validates a CIDR by ensuring it is trimmed, is lowercase, has a valid format and is a public IP.
  """
  def validate_cidr(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> ensure_trimmed(field)
    |> ensure_lowercase(field)
    |> validate_change(field, fn ^field, value ->
      case Util.CIDR.parse(value) do
        %Util.CIDR{} -> []
        {:error, _} -> [{field, "is invalid"}]
      end
    end)
  end

  @doc """
  Validates the state and verifies it is allowed by the transitions.
  """
  def validate_state(%Ecto.Changeset{} = changeset, transitions, field \\ :state)
      when is_list(transitions) and is_atom(field) do
    states =
      transitions
      |> Enum.flat_map(fn {source, dests} -> [source | dests] end)
      |> Enum.uniq()

    changeset
    |> validate_required([field])
    |> validate_inclusion(field, states)
    |> validate_state_transition(transitions, states, field)
  end

  def validate_profanities(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn ^field, value ->
      case Passwordless.SwearJar.profanities(value) do
        [_ | _] = list ->
          [{field, "let's keep it professional, please :) - " <> Enum.join(list, ", ")}]

        _ ->
          []
      end
    end)
  end

  @doc """
  Ensure that the personal identifiable information (PIA) is removed from the value.
  """
  def ensure_pia_removed(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    update_change(changeset, field, &remove_pia/1)
  end

  @doc """
  Validates that at least one of the fields is required.
  """
  def validate_at_least_one_required(%Ecto.Changeset{} = changeset, fields) when is_list(fields) do
    if Enum.any?(fields, &changed?(changeset, &1)),
      do: changeset,
      else: add_error(changeset, :action, "at least one of #{inspect(fields)} is required")
  end

  @doc """
  Validates that the property map is valid.
  """
  def validate_property_map(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn ^field, props ->
      if Util.validate_property_map(props), do: [], else: [{field, "is not a valid property map"}]
    end)
  end

  @doc """
  Ensures that the property map is valid and casts it to the correct format.
  """
  def ensure_property_map(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> update_change(field, &Util.cast_property_map/1)
    |> validate_property_map(field)
  end

  def validate_semver(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn ^field, version ->
      is_semver? =
        case Version.parse(version) do
          {:ok, _} -> true
          _ -> false
        end

      if is_semver?, do: [], else: [{field, "is not a valid semantic version (e.g. 1.2.4)"}]
    end)
  end

  def validate_crontab(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn ^field, cron ->
      case CronParser.parse(cron) do
        {:ok, _} -> []
        {:error, _} -> [{field, "is not a valid crontab"}]
      end
    end)
  end

  @doc """
  When working with a field that is an array of strings, this
  function sorts the values in the array.
  """
  def sort_array(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &Enum.sort/1)
  end

  @doc """
  When working with a field that is an array of strings, this
  function removes any duplicate values.
  """
  def uniq_array(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &Enum.uniq/1)
  end

  @doc """
  Remove the blank value from the array.
  """
  def trim_array(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &Enum.reject(&1, fn item -> Util.blank?(item) end))
  end

  @doc """
  Clean and process the array values and validate the selected
  values against an approved list.
  """
  def clean_array(%Ecto.Changeset{} = changeset, field) do
    changeset
    |> trim_array(field)
    |> uniq_array(field)
    |> sort_array(field)
  end

  @doc """
  Ensure the variable name is in the correct format.
  """
  def ensure_variable_notation(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &Util.StringExt.variable_name/1)
  end

  @doc """
  Create a soft delete changeset.
  """
  def soft_delete(struct_or_changeset) do
    Ecto.Changeset.change(struct_or_changeset, deleted_at: DateTime.utc_now())
  end

  # Private

  defp validate_state_transition(%Ecto.Changeset{valid?: true} = changeset, transitions, states, field)
       when is_list(transitions) and is_atom(field) do
    case {fetch_field(changeset, field), fetch_change(changeset, field)} do
      {{:changes, new_state}, {:ok, new_state}}
      when is_atom(new_state) and not is_nil(new_state) ->
        if Enum.member?(states, new_state),
          do: changeset,
          else: add_error(changeset, :state, "is invalid")

      {{:data, old_state}, {:ok, new_state}}
      when is_atom(old_state) and
             is_atom(new_state) and
             not is_nil(old_state) and
             not is_nil(new_state) ->
        if new_state in (transitions[old_state] || []),
          do: changeset,
          else: add_error(changeset, :state, "is invalid")

      _ ->
        changeset
    end
  end

  defp validate_state_transition(%Ecto.Changeset{} = changeset, _transitions, _states, _field), do: changeset

  defp trim(nil), do: nil
  defp trim(str) when is_binary(str), do: String.trim(str)

  defp downcase(nil), do: nil
  defp downcase(str) when is_binary(str), do: String.downcase(str)

  defp remove_pia(value) when is_struct(value), do: remove_pia(Map.from_struct(value))

  defp remove_pia(value) when is_map(value) do
    Map.new(value, fn {k, v} ->
      if sensitive?(k),
        do: {k, @redacted},
        else: {k, remove_pia(v)}
    end)
  end

  defp remove_pia(value) when is_list(value) do
    Enum.map(value, &remove_pia/1)
  end

  defp remove_pia(value) when is_function(value) do
    "<function>"
  end

  defp remove_pia({:file, name, mime, _content}) do
    %{file: %{name: name, mime: mime}}
  end

  defp remove_pia({k, v}) when is_atom(k) or is_binary(k) do
    if sensitive?(k),
      do: {k, @redacted},
      else: {k, remove_pia(v)}
  end

  defp remove_pia(value), do: value

  defp sensitive?(key) when is_atom(key) and key in @sensitive_keys, do: true
  defp sensitive?(key) when is_binary(key) and key in @sensitive_keys_s, do: true
  defp sensitive?(_key), do: false

  defp public_ip?(ip_address) do
    case ip_address do
      {10, _, _, _} -> false
      {192, 168, _, _} -> false
      {172, second, _, _} when second >= 16 and second <= 31 -> false
      {127, 0, 0, _} -> false
      {_, _, _, _} -> true
      :einval -> false
      _ -> false
    end
  end
end

defmodule Tally.Ingest.Payload do
  @moduledoc """
  The wire format sent by the tracking script (`script/tally.ts`) to `POST /api/event`.

  Keys are one letter to keep the script and the request small:

  | key | meaning                                                  |
  | --- | -------------------------------------------------------- |
  | `n` | event name: `"pageview"` or a custom goal name           |
  | `u` | full page URL, including UTM parameters                  |
  | `r` | `document.referrer`, or `null`                           |
  | `w` | viewport width in CSS pixels (for the screen-size class) |
  | `d` | site domain from the script's `data-site` attribute      |
  | `p` | optional custom properties                               |
  | `$` | optional revenue: `{"amount": 64.0, "currency": "USD"}`  |

  `parse/1` decodes and validates a raw body; `validate/1` validates an already decoded map. Errors
  are returned per field so the response can say exactly what was wrong.
  """

  @enforce_keys [:name, :url, :referrer, :width, :domain]
  defstruct [:name, :url, :referrer, :width, :domain, props: %{}, revenue: nil]

  @type revenue :: %{amount: number(), currency: String.t()}
  @type t :: %__MODULE__{
          name: String.t(),
          url: URI.t(),
          referrer: String.t() | nil,
          width: non_neg_integer(),
          domain: String.t(),
          props: %{optional(String.t()) => String.t() | number() | boolean()},
          revenue: revenue() | nil
        }

  @type errors :: %{optional(String.t()) => [String.t()]}

  @max_body_bytes 16_384
  @max_name 120
  @max_url 2048
  @max_width 10_000
  @max_props 30
  @max_prop_key 64
  @max_prop_value 256
  @max_amount 1_000_000_000

  @doc "Largest request body accepted, in bytes."
  def max_body_bytes, do: @max_body_bytes

  @doc """
  Decodes a JSON body and validates it.
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_json} | {:error, {:invalid, errors()}}
  def parse(body) when is_binary(body) and byte_size(body) <= @max_body_bytes do
    case Jason.decode(body) do
      {:ok, map} when is_map(map) -> validate(map)
      {:ok, _not_an_object} -> {:error, {:invalid, %{"_" => ["must be a JSON object"]}}}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  def parse(body) when is_binary(body), do: {:error, {:invalid, %{"_" => ["body is too large"]}}}

  @doc """
  Validates a decoded payload map. Unknown keys are ignored.
  """
  @spec validate(map()) :: {:ok, t()} | {:error, {:invalid, errors()}}
  def validate(map) when is_map(map) do
    results = [
      name: field(map, "n", &name/1),
      url: field(map, "u", &url/1),
      referrer: field(map, "r", &referrer/1),
      width: field(map, "w", &width/1),
      domain: field(map, "d", &domain/1),
      props: optional_field(map, "p", &props/1, %{}),
      revenue: optional_field(map, "$", &revenue/1, nil)
    ]

    errors =
      for {_field, {:error, key, messages}} <- results, into: %{} do
        {key, messages}
      end

    if errors == %{} do
      {:ok,
       struct!(__MODULE__, Enum.map(results, fn {field, {:ok, value}} -> {field, value} end))}
    else
      {:error, {:invalid, errors}}
    end
  end

  # -- fields -------------------------------------------------------------------------------------

  defp field(map, key, validator) do
    case Map.fetch(map, key) do
      {:ok, value} -> tag(key, validator.(value))
      :error -> {:error, key, ["is required"]}
    end
  end

  defp optional_field(map, key, validator, default) do
    case Map.get(map, key) do
      nil -> {:ok, default}
      value -> tag(key, validator.(value))
    end
  end

  defp tag(_key, {:ok, value}), do: {:ok, value}
  defp tag(key, {:error, messages}) when is_list(messages), do: {:error, key, messages}
  defp tag(key, {:error, message}), do: {:error, key, [message]}

  defp name(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:error, "must not be blank"}
      String.length(trimmed) > @max_name -> {:error, "must be at most #{@max_name} characters"}
      true -> {:ok, trimmed}
    end
  end

  defp name(_), do: {:error, "must be a string"}

  defp url(value) when is_binary(value) and byte_size(value) > @max_url,
    do: {:error, "must be at most #{@max_url} characters"}

  defp url(value) when is_binary(value) do
    case URI.new(value) do
      {:ok, %URI{scheme: scheme, host: host} = uri}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        {:ok, uri}

      _ ->
        {:error, "must be an absolute http(s) URL"}
    end
  end

  defp url(_), do: {:error, "must be a string"}

  defp referrer(nil), do: {:ok, nil}

  defp referrer(value) when is_binary(value) and byte_size(value) > @max_url,
    do: {:error, "must be at most #{@max_url} characters"}

  defp referrer(""), do: {:ok, nil}
  defp referrer(value) when is_binary(value), do: {:ok, value}
  defp referrer(_), do: {:error, "must be a string or null"}

  defp width(value) when is_integer(value) and value >= 0 and value <= @max_width,
    do: {:ok, value}

  defp width(value) when is_integer(value),
    do: {:error, "must be between 0 and #{@max_width}"}

  defp width(_), do: {:error, "must be an integer"}

  defp domain(value) when is_binary(value) do
    normalized = value |> String.trim() |> String.downcase()

    cond do
      byte_size(normalized) < 3 -> {:error, "must be at least 3 characters"}
      byte_size(normalized) > 253 -> {:error, "must be at most 253 characters"}
      not String.match?(normalized, ~r/^[a-z0-9.-]+$/) -> {:error, "must be a domain name"}
      true -> {:ok, normalized}
    end
  end

  defp domain(_), do: {:error, "must be a string"}

  defp props(value) when is_map(value) and map_size(value) > @max_props,
    do: {:error, "must have at most #{@max_props} properties"}

  defp props(value) when is_map(value) do
    {valid, errors} =
      Enum.reduce(value, {%{}, []}, fn {key, prop}, {valid, errors} ->
        case prop(key, prop) do
          {:ok, normalized} -> {Map.put(valid, key, normalized), errors}
          {:error, message} -> {valid, ["#{key} #{message}" | errors]}
        end
      end)

    if errors == [], do: {:ok, valid}, else: {:error, Enum.sort(errors)}
  end

  defp props(_), do: {:error, "must be an object"}

  defp prop(key, _value) when byte_size(key) > @max_prop_key,
    do: {:error, "name must be at most #{@max_prop_key} characters"}

  defp prop(_key, value) when is_binary(value) and byte_size(value) > @max_prop_value,
    do: {:error, "must be at most #{@max_prop_value} characters"}

  defp prop(_key, value) when is_binary(value) or is_number(value) or is_boolean(value),
    do: {:ok, value}

  defp prop(_key, _value), do: {:error, "must be a string, number or boolean"}

  defp revenue(%{"amount" => amount, "currency" => currency})
       when is_number(amount) and is_binary(currency) do
    code = String.upcase(currency)

    cond do
      amount < 0 -> {:error, "amount must not be negative"}
      amount > @max_amount -> {:error, "amount is too large"}
      not String.match?(code, ~r/^[A-Z]{3}$/) -> {:error, "currency must be a 3-letter ISO code"}
      true -> {:ok, %{amount: amount, currency: code}}
    end
  end

  defp revenue(%{} = value) do
    missing = for key <- ["amount", "currency"], not Map.has_key?(value, key), do: key

    case missing do
      [] -> {:error, "amount must be a number and currency a string"}
      keys -> {:error, "missing #{Enum.join(keys, " and ")}"}
    end
  end

  defp revenue(_), do: {:error, "must be an object with amount and currency"}
end

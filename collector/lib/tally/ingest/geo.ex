defmodule Tally.Ingest.Geo do
  @moduledoc """
  Country and client IP from request headers.

  The country comes from the edge network's geo header (Cloudflare, Vercel, Fly, or a generic
  `x-country-code` set by a proxy). The client IP is only read so it can go into the daily visitor
  hash; it is never persisted or logged.
  """

  @country_headers [
    "cf-ipcountry",
    "x-vercel-ip-country",
    "fly-client-ip-country",
    "x-country-code"
  ]

  @doc """
  ISO 3166-1 alpha-2 country code from geo headers, or `nil`. Placeholder codes such as `XX` (unknown)
  and `T1` (Tor) are ignored.
  """
  @spec country([{String.t(), String.t()}]) :: String.t() | nil
  def country(headers) when is_list(headers) do
    Enum.find_value(@country_headers, fn name ->
      with value when is_binary(value) <- header(headers, name),
           code = value |> String.trim() |> String.upcase(),
           true <- Regex.match?(~r/^[A-Z]{2}$/, code),
           false <- code in ["XX", "T1", "ZZ"] do
        code
      else
        _ -> nil
      end
    end)
  end

  @doc """
  The client IP as a string: the first address in `x-forwarded-for`, then `x-real-ip`, then the
  socket's peer address.
  """
  @spec client_ip([{String.t(), String.t()}], :inet.ip_address() | nil) :: String.t()
  def client_ip(headers, remote_ip \\ nil) when is_list(headers) do
    forwarded =
      case header(headers, "x-forwarded-for") do
        nil -> nil
        value -> value |> String.split(",") |> hd() |> String.trim() |> blank_to_nil()
      end

    forwarded || blank_to_nil(header(headers, "x-real-ip")) || format_ip(remote_ip)
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {key, value} -> String.downcase(key) == name && value end)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(value), do: if(String.trim(value) == "", do: nil, else: String.trim(value))

  defp format_ip(nil), do: "0.0.0.0"
  defp format_ip(ip) when is_tuple(ip), do: ip |> :inet.ntoa() |> to_string()
end

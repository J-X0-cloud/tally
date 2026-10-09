defmodule Tally.Billing.ApiKeys do
  @moduledoc """
  Stats API keys and the plan each one belongs to, configured with `TALLY_API_KEYS`
  (`"key:plan,key:plan"`). Keys are compared in constant time.
  """

  @doc """
  The plan for a key, or `:error` for an unknown key.
  """
  @spec lookup(String.t() | nil) :: {:ok, String.t()} | :error
  def lookup(key) when is_binary(key) and byte_size(key) > 0 do
    Enum.find_value(keys(), :error, fn {known, plan} ->
      byte_size(known) == byte_size(key) and Plug.Crypto.secure_compare(known, key) and
        {:ok, plan}
    end)
  end

  def lookup(_), do: :error

  @doc """
  A stable, non-reversible identifier for a key, for rate-limit buckets and logs.
  """
  @spec fingerprint(String.t()) :: String.t()
  def fingerprint(key) do
    :crypto.hash(:sha256, key) |> Base.encode16(case: :lower) |> binary_part(0, 12)
  end

  defp keys, do: Application.get_env(:tally, :api_keys, %{})
end

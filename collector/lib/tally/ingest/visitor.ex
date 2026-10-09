defmodule Tally.Ingest.Visitor do
  @moduledoc """
  Anonymous visitor ids.

  An id is `sha256(daily salt <> site <> ip <> user agent)`, hex encoded and truncated to 16
  characters. It tells visitors apart within one site on one day. Because the salt is random and
  deleted after the day ends, the same person gets an unrelated id tomorrow and on every other site.
  """

  alias Tally.Ingest.Salts

  @id_length 16

  @doc """
  The visitor id for a request, using the salt for the UTC day of `now`.
  """
  @spec id(GenServer.server(), String.t(), String.t(), String.t(), DateTime.t()) :: String.t()
  def id(salts \\ Salts, site, ip, user_agent, %DateTime{} = now) do
    salts
    |> Salts.salt_for(DateTime.to_date(now))
    |> hash(site, ip, user_agent)
  end

  @doc """
  The hash itself, for a known salt.
  """
  @spec hash(binary(), String.t(), String.t(), String.t()) :: String.t()
  def hash(salt, site, ip, user_agent) do
    :crypto.hash(:sha256, [salt, site, ip, user_agent])
    |> Base.encode16(case: :lower)
    |> binary_part(0, @id_length)
  end
end

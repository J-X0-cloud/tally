defmodule Tally.Sites do
  @moduledoc """
  The sites this deployment accepts events for, and the goals and funnels configured for them.

  Domains come from `TALLY_SITES` (see `config/runtime.exs`). Goals and funnels are defined in
  `config/config.exs`; every site shares them unless the site list entry is a map that overrides
  them:

      config :tally, Tally.Sites,
        sites: ["harrowfield.co", %{domain: "shop.example.com", goals: [...], funnels: [...]}]
  """

  alias Tally.Stats.Funnel
  alias Tally.Stats.Goal

  @type domain :: String.t()

  @doc """
  All configured site domains, lowercased.
  """
  @spec domains() :: [domain()]
  def domains do
    config()
    |> Keyword.get(:sites, [])
    |> Enum.map(&entry_domain/1)
  end

  @doc """
  Normalises a domain the way the tracking script and the stats API may send it: trimmed,
  lowercased, without a scheme, a `www.` prefix, a port or a trailing slash.
  """
  @spec normalize(String.t()) :: domain()
  def normalize(domain) when is_binary(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r{^[a-z][a-z0-9+.-]*://}, "")
    |> String.replace(~r{[/?#].*$}, "")
    |> String.replace(~r{:\d+$}, "")
    |> String.replace_prefix("www.", "")
  end

  @doc """
  Whether events for `domain` are accepted. Lookup is on the normalised domain, so `www.` variants of
  a configured site are accepted too.
  """
  @spec allowed?(String.t()) :: boolean()
  def allowed?(domain) when is_binary(domain), do: normalize(domain) in domains()
  def allowed?(_), do: false

  @doc """
  Fetches a configured site by domain.
  """
  @spec fetch(String.t()) :: {:ok, domain()} | {:error, {:not_found, String.t()}}
  def fetch(domain) when is_binary(domain) do
    normalized = normalize(domain)
    if normalized in domains(), do: {:ok, normalized}, else: {:error, {:not_found, "site"}}
  end

  @doc """
  Goals for a site, as `Tally.Stats.Goal` structs.
  """
  @spec goals(domain()) :: [Goal.t()]
  def goals(domain) do
    domain
    |> setting(:goals)
    |> Enum.map(&Goal.new!/1)
  end

  @doc """
  Funnels for a site, as `Tally.Stats.Funnel` structs.
  """
  @spec funnels(domain()) :: [Funnel.t()]
  def funnels(domain) do
    domain
    |> setting(:funnels)
    |> Enum.map(&Funnel.new!/1)
  end

  @doc """
  Looks up one funnel by name (case-insensitive).
  """
  @spec funnel(domain(), String.t()) :: {:ok, Funnel.t()} | {:error, {:not_found, String.t()}}
  def funnel(domain, name) do
    wanted = String.downcase(name)

    case Enum.find(funnels(domain), &(String.downcase(&1.name) == wanted)) do
      nil -> {:error, {:not_found, "funnel"}}
      funnel -> {:ok, funnel}
    end
  end

  defp setting(domain, key) do
    site_entry =
      config()
      |> Keyword.get(:sites, [])
      |> Enum.find(&(entry_domain(&1) == domain))

    case site_entry do
      %{^key => value} -> value
      _ -> Keyword.get(config(), key, [])
    end
  end

  defp entry_domain(%{domain: domain}), do: normalize(domain)
  defp entry_domain(domain) when is_binary(domain), do: normalize(domain)

  defp config, do: Application.get_env(:tally, __MODULE__, [])
end

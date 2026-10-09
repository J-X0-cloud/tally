defmodule Tally.Ingest.Referrer do
  @moduledoc """
  Classifies a visit into the source and channel shown in the Top sources panel, from the page's
  UTM parameters and the referrer.

  Precedence:

    1. `utm_medium` of email/newsletter or cpc/ppc/paid decides the channel outright.
    2. A referrer from another host is matched against known search engines, social networks and AI
       assistants; anything else is a Referral from that host.
    3. No referrer (or an internal one) is Direct, unless a `utm_source` names the source.

  Only the referrer's host is kept, never the full referrer URL.
  """

  @type channel ::
          String.t()

  @type attribution :: %{
          source: String.t(),
          channel: channel(),
          utm: %{optional(String.t()) => String.t()}
        }

  @channels [
    "Organic Search",
    "Paid Search",
    "Organic Social",
    "Paid Social",
    "Email",
    "AI Assistants",
    "Referral",
    "Direct"
  ]

  @utm_keys ~w(source medium campaign term content)
  @max_utm 100

  # Gemini is listed before Google: gemini.google.com would otherwise match the Google pattern.
  @known_sources [
    {~r/(^|\.)gemini\.google\.com$/, "Gemini", "AI Assistants"},
    {~r/(^|\.)google\.[a-z.]+$/, "Google", "Organic Search"},
    {~r/(^|\.)bing\.com$/, "Bing", "Organic Search"},
    {~r/(^|\.)duckduckgo\.com$/, "DuckDuckGo", "Organic Search"},
    {~r/(^|\.)search\.yahoo\.com$/, "Yahoo", "Organic Search"},
    {~r/(^|\.)ecosia\.org$/, "Ecosia", "Organic Search"},
    {~r/(^|\.)search\.brave\.com$/, "Brave Search", "Organic Search"},
    {~r/(^|\.)(chatgpt\.com|chat\.openai\.com)$/, "ChatGPT", "AI Assistants"},
    {~r/(^|\.)perplexity\.ai$/, "Perplexity", "AI Assistants"},
    {~r/(^|\.)claude\.ai$/, "Claude", "AI Assistants"},
    {~r/(^|\.)copilot\.microsoft\.com$/, "Copilot", "AI Assistants"},
    {~r/(^|\.)(instagram\.com|l\.instagram\.com)$/, "Instagram", "Organic Social"},
    {~r/(^|\.)pinterest\.[a-z.]+$/, "Pinterest", "Organic Social"},
    {~r/(^|\.)(facebook\.com|fb\.me|l\.facebook\.com|m\.facebook\.com)$/, "Facebook",
     "Organic Social"},
    {~r/(^|\.)reddit\.com$/, "Reddit", "Organic Social"},
    {~r/(^|\.)(t\.co|x\.com|twitter\.com)$/, "X", "Organic Social"},
    {~r/(^|\.)(linkedin\.com|lnkd\.in)$/, "LinkedIn", "Organic Social"},
    {~r/(^|\.)(youtube\.com|youtu\.be)$/, "YouTube", "Organic Social"},
    {~r/(^|\.)tiktok\.com$/, "TikTok", "Organic Social"},
    {~r/(^|\.)news\.ycombinator\.com$/, "Hacker News", "Organic Social"}
  ]

  @doc "All channel names, in display order."
  @spec channels() :: [channel()]
  def channels, do: @channels

  @doc """
  Attribution for a page view.

      iex> uri = URI.parse("https://harrowfield.co/shop/mugs?utm_source=insta&utm_medium=social")
      iex> Tally.Ingest.Referrer.attribute(uri, "https://l.instagram.com/")
      %{source: "Instagram", channel: "Organic Social", utm: %{"medium" => "social", "source" => "insta"}}
  """
  @spec attribute(URI.t(), String.t() | nil) :: attribution()
  def attribute(%URI{} = page, referrer) do
    utm = utm_params(page)
    medium = utm |> Map.get("medium", "") |> String.downcase()

    cond do
      medium in ["email", "e-mail", "newsletter"] ->
        %{source: Map.get(utm, "source", "Newsletter"), channel: "Email", utm: utm}

      medium in ["cpc", "ppc", "paid", "paidsearch", "paid_search"] ->
        %{source: Map.get(utm, "source", "Paid"), channel: "Paid Search", utm: utm}

      medium in ["paid_social", "paidsocial", "social_paid"] ->
        %{source: Map.get(utm, "source", "Paid social"), channel: "Paid Social", utm: utm}

      true ->
        from_referrer(page, referrer, utm)
    end
  end

  @doc """
  The UTM parameters of a page URL, keyed without the `utm_` prefix and capped at 100 characters.
  """
  @spec utm_params(URI.t()) :: %{optional(String.t()) => String.t()}
  def utm_params(%URI{query: nil}), do: %{}

  def utm_params(%URI{query: query}) do
    params = decode_query(query)

    for key <- @utm_keys,
        value = Map.get(params, "utm_" <> key),
        is_binary(value),
        String.valid?(value),
        trimmed = String.trim(value),
        trimmed != "",
        into: %{} do
      {key, String.slice(trimmed, 0, @max_utm)}
    end
  end

  @doc """
  The host of a referrer URL without a `www.` prefix, or `nil` when it cannot be parsed.
  """
  @spec referrer_host(String.t() | nil) :: String.t() | nil
  def referrer_host(nil), do: nil

  def referrer_host(referrer) when is_binary(referrer) do
    case URI.new(referrer) do
      {:ok, %URI{host: host}} when is_binary(host) and host != "" -> strip_www(host)
      _ -> nil
    end
  end

  defp from_referrer(page, referrer, utm) do
    host = referrer_host(referrer)

    # Internal navigation isn't a new source.
    if is_nil(host) or host == strip_www(page.host) do
      case utm do
        %{"source" => source} -> %{source: source, channel: "Referral", utm: utm}
        _ -> %{source: "Direct / None", channel: "Direct", utm: utm}
      end
    else
      case Enum.find(@known_sources, fn {pattern, _, _} -> Regex.match?(pattern, host) end) do
        {_pattern, source, channel} -> %{source: source, channel: channel, utm: utm}
        nil -> %{source: host, channel: "Referral", utm: utm}
      end
    end
  end

  defp strip_www(host), do: host |> String.downcase() |> String.replace_prefix("www.", "")

  # URI.decode_query/1 raises on some malformed percent-encoding and returns invalid UTF-8 for other
  # cases; a bad query string should only cost the UTM tags, not the event.
  defp decode_query(query) do
    URI.decode_query(query)
  rescue
    ArgumentError -> %{}
  end
end

defmodule Tally.Ingest.Device do
  @moduledoc """
  Device information derived from a request: the screen-size class from the viewport width, and the
  browser and operating system families from the user agent.

  Only the families are kept. The exact width, browser version and the user agent string itself are
  never stored.
  """

  @type screen :: String.t()

  @screen_classes [{576, "Mobile"}, {992, "Tablet"}, {1440, "Laptop"}]

  # Order matters: many browsers include "Chrome" and "Safari" in their user agent, so the more
  # specific tokens are checked first.
  @browsers [
    {~r/SamsungBrowser/, "Samsung Internet"},
    {~r/OPR\/|Opera/, "Opera"},
    {~r/Edg(e|A|iOS)?\//, "Edge"},
    {~r/Brave/, "Brave"},
    {~r/DuckDuckGo\//, "DuckDuckGo"},
    {~r/Firefox\/|FxiOS\//, "Firefox"},
    {~r/Chrome\/|CriOS\//, "Chrome"},
    {~r/Safari\//, "Safari"}
  ]

  @systems [
    {~r/iPad/, "iPadOS"},
    {~r/iPhone|iPod/, "iOS"},
    {~r/Android/, "Android"},
    {~r/CrOS/, "ChromeOS"},
    {~r/Mac OS X|Macintosh/, "macOS"},
    {~r/Windows/, "Windows"},
    {~r/Linux/, "Linux"}
  ]

  @bot ~r/bot|crawl|spider|slurp|headless|lighthouse|pingdom|uptime|monitor|preview|python-requests|curl\/|wget|go-http-client|okhttp|axios|node-fetch|phantomjs|selenium|puppeteer|playwright/i

  @doc """
  Screen-size class from a viewport width in CSS pixels.

      iex> Tally.Ingest.Device.screen_class(390)
      "Mobile"
      iex> Tally.Ingest.Device.screen_class(1280)
      "Laptop"
  """
  @spec screen_class(non_neg_integer()) :: screen()
  def screen_class(width) when is_integer(width) and width >= 0 do
    Enum.find_value(@screen_classes, "Desktop", fn {limit, class} -> width < limit && class end)
  end

  @doc """
  Every screen class, smallest first.
  """
  @spec screen_classes() :: [screen()]
  def screen_classes, do: Enum.map(@screen_classes, &elem(&1, 1)) ++ ["Desktop"]

  @doc """
  Browser and OS families from a user agent string. Unknown values are `"Other"`.

      iex> Tally.Ingest.Device.user_agent("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1")
      %{browser: "Safari", os: "iOS"}
  """
  @spec user_agent(String.t()) :: %{browser: String.t(), os: String.t()}
  def user_agent(ua) when is_binary(ua) do
    %{browser: first_match(@browsers, ua), os: first_match(@systems, ua)}
  end

  @doc """
  Whether a user agent belongs to a crawler, monitor or scripted client. An empty user agent counts as
  a bot: every real browser sends one.
  """
  @spec bot?(String.t() | nil) :: boolean()
  def bot?(nil), do: true
  def bot?(""), do: true
  def bot?(ua) when is_binary(ua), do: Regex.match?(@bot, ua)

  defp first_match(patterns, ua) do
    Enum.find_value(patterns, "Other", fn {pattern, name} -> Regex.match?(pattern, ua) && name end)
  end
end

defmodule Tally.Ingest.DeviceTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Device

  doctest Device

  @agents %{
    safari_mac:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15",
    chrome_windows:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36",
    edge_windows:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0",
    firefox_linux: "Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0",
    samsung_android:
      "Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/26.0 Chrome/122.0.0.0 Mobile Safari/537.36",
    chrome_ios:
      "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/129.0.6668.69 Mobile/15E148 Safari/604.1",
    safari_ipad:
      "Mozilla/5.0 (iPad; CPU OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Mobile/15E148 Safari/604.1",
    opera_windows:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 OPR/114.0.0.0",
    chromebook:
      "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
  }

  describe "user_agent/1" do
    test "recognises browser and OS families" do
      expectations = %{
        safari_mac: %{browser: "Safari", os: "macOS"},
        chrome_windows: %{browser: "Chrome", os: "Windows"},
        edge_windows: %{browser: "Edge", os: "Windows"},
        firefox_linux: %{browser: "Firefox", os: "Linux"},
        samsung_android: %{browser: "Samsung Internet", os: "Android"},
        chrome_ios: %{browser: "Chrome", os: "iOS"},
        safari_ipad: %{browser: "Safari", os: "iPadOS"},
        opera_windows: %{browser: "Opera", os: "Windows"},
        chromebook: %{browser: "Chrome", os: "ChromeOS"}
      }

      for {agent, expected} <- expectations do
        assert Device.user_agent(@agents[agent]) == expected, "for #{agent}"
      end
    end

    test "falls back to Other" do
      assert Device.user_agent("SomethingNew/1.0") == %{browser: "Other", os: "Other"}
    end
  end

  describe "screen_class/1" do
    test "uses the breakpoint boundaries" do
      assert Device.screen_class(0) == "Mobile"
      assert Device.screen_class(575) == "Mobile"
      assert Device.screen_class(576) == "Tablet"
      assert Device.screen_class(991) == "Tablet"
      assert Device.screen_class(992) == "Laptop"
      assert Device.screen_class(1439) == "Laptop"
      assert Device.screen_class(1440) == "Desktop"
      assert Device.screen_class(3840) == "Desktop"
    end

    test "lists the classes smallest first" do
      assert Device.screen_classes() == ["Mobile", "Tablet", "Laptop", "Desktop"]
    end
  end

  describe "bot?/1" do
    test "flags crawlers, monitors and scripted clients" do
      for ua <- [
            "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 HeadlessChrome/129.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Linux; Android 11; moto g power (2022)) Chrome-Lighthouse",
            "curl/8.7.1",
            "python-requests/2.32.3",
            "Wget/1.21.4",
            "Pingdom.com_bot_version_1.4",
            "UptimeRobot/2.0",
            "Go-http-client/2.0",
            "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php) Preview"
          ] do
        assert Device.bot?(ua), "expected #{ua} to be a bot"
      end
    end

    test "treats a missing user agent as a bot" do
      assert Device.bot?(nil)
      assert Device.bot?("")
    end

    test "lets real browsers through" do
      for {_name, ua} <- @agents, do: refute(Device.bot?(ua))
    end
  end
end

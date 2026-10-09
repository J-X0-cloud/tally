defmodule Tally.Ingest.ReferrerTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Referrer

  doctest Referrer

  defp attribute(url, referrer), do: Referrer.attribute(URI.parse(url), referrer)

  describe "attribute/2 from referrers" do
    test "known search engines are Organic Search" do
      assert %{source: "Google", channel: "Organic Search"} =
               attribute("https://harrowfield.co/", "https://www.google.com/")

      assert %{source: "Google", channel: "Organic Search"} =
               attribute("https://harrowfield.co/", "https://www.google.co.uk/search?q=mugs")

      assert %{source: "Bing", channel: "Organic Search"} =
               attribute("https://harrowfield.co/", "https://www.bing.com/")

      assert %{source: "DuckDuckGo", channel: "Organic Search"} =
               attribute("https://harrowfield.co/", "https://duckduckgo.com/")
    end

    test "AI assistants have their own channel" do
      assert %{source: "ChatGPT", channel: "AI Assistants"} =
               attribute("https://harrowfield.co/journal/how-we-glaze", "https://chatgpt.com/")

      assert %{source: "Perplexity", channel: "AI Assistants"} =
               attribute("https://harrowfield.co/", "https://www.perplexity.ai/search/x")

      assert %{source: "Gemini", channel: "AI Assistants"} =
               attribute("https://harrowfield.co/", "https://gemini.google.com/app")
    end

    test "social networks are Organic Social" do
      for {referrer, source} <- [
            {"https://l.instagram.com/?u=x", "Instagram"},
            {"https://www.pinterest.com/pin/1", "Pinterest"},
            {"https://m.facebook.com/", "Facebook"},
            {"https://old.reddit.com/r/Pottery", "Reddit"},
            {"https://t.co/abc", "X"},
            {"https://www.linkedin.com/feed/", "LinkedIn"}
          ] do
        assert %{source: ^source, channel: "Organic Social"} =
                 attribute("https://harrowfield.co/", referrer)
      end
    end

    test "unknown hosts are Referrals named by host, without www" do
      assert %{source: "potterynotes.blog", channel: "Referral"} =
               attribute("https://harrowfield.co/", "https://www.potterynotes.blog/best-mugs")
    end

    test "no referrer is Direct" do
      assert %{source: "Direct / None", channel: "Direct", utm: %{}} =
               attribute("https://harrowfield.co/", nil)
    end

    test "internal navigation is not a new source" do
      assert %{channel: "Direct"} =
               attribute("https://harrowfield.co/cart", "https://www.harrowfield.co/shop/mugs")
    end

    test "an unparseable referrer counts as no referrer" do
      assert %{channel: "Direct"} = attribute("https://harrowfield.co/", "not a url")
    end
  end

  describe "attribute/2 from UTM tags" do
    test "email mediums win over the referrer" do
      assert %{source: "sept-news", channel: "Email"} =
               attribute(
                 "https://harrowfield.co/?utm_source=sept-news&utm_medium=email",
                 "https://mail.google.com/"
               )

      assert %{source: "Newsletter", channel: "Email"} =
               attribute("https://harrowfield.co/?utm_medium=Newsletter", nil)
    end

    test "paid mediums are Paid Search or Paid Social" do
      assert %{source: "google", channel: "Paid Search"} =
               attribute("https://harrowfield.co/?utm_source=google&utm_medium=cpc", nil)

      assert %{source: "Paid", channel: "Paid Search"} =
               attribute("https://harrowfield.co/?utm_medium=ppc", nil)

      assert %{source: "meta", channel: "Paid Social"} =
               attribute("https://harrowfield.co/?utm_source=meta&utm_medium=paid_social", nil)
    end

    test "a utm_source without a referrer is a Referral from that source" do
      assert %{source: "podcast", channel: "Referral"} =
               attribute("https://harrowfield.co/?utm_source=podcast", nil)
    end

    test "collects all five UTM parameters and caps their length" do
      long = String.duplicate("x", 150)

      url =
        "https://harrowfield.co/?utm_source=ig&utm_medium=social&utm_campaign=#{long}" <>
          "&utm_term=mugs&utm_content=reel-2&other=1"

      assert %{utm: utm} = attribute(url, nil)
      assert utm["source"] == "ig"
      assert utm["medium"] == "social"
      assert utm["term"] == "mugs"
      assert utm["content"] == "reel-2"
      assert String.length(utm["campaign"]) == 100
      refute Map.has_key?(utm, "other")
    end

    test "ignores blank UTM values and malformed query strings" do
      assert Referrer.utm_params(URI.parse("https://a.co/?utm_source=&utm_medium=%20")) == %{}
      assert Referrer.utm_params(URI.parse("https://a.co/?utm_source=%E0%A4%A")) == %{}
    end
  end

  test "referrer_host/1" do
    assert Referrer.referrer_host("https://www.Example.com/path") == "example.com"
    assert Referrer.referrer_host(nil) == nil
    assert Referrer.referrer_host("android-app://") == nil
  end

  test "channels/0 lists every channel" do
    assert "Direct" in Referrer.channels()
    assert "AI Assistants" in Referrer.channels()
  end
end

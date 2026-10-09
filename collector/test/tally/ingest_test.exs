defmodule Tally.IngestTest do
  use ExUnit.Case, async: true

  alias Tally.Events.Event
  alias Tally.Ingest

  doctest Ingest

  @ua "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

  defp request(extra_headers \\ []) do
    %{
      headers:
        [{"user-agent", @ua}, {"x-forwarded-for", "203.0.113.7"}, {"cf-ipcountry", "US"}] ++
          extra_headers,
      remote_ip: {10, 0, 0, 1},
      received_at: ~U[2026-09-25 21:40:12.345678Z]
    }
  end

  defp body(overrides \\ %{}) do
    %{
      "n" => "pageview",
      "u" => "https://harrowfield.co/shop/mugs/?utm_source=insta&utm_medium=social",
      "r" => "https://l.instagram.com/",
      "w" => 390,
      "d" => "harrowfield.co"
    }
    |> Map.merge(overrides)
    |> Jason.encode!()
  end

  test "builds an anonymous event from a page view" do
    assert {:ok, %Event{} = event} = Ingest.build_event(body(), request())

    assert event.site == "harrowfield.co"
    assert event.name == "pageview"
    assert event.timestamp == ~U[2026-09-25 21:40:12.345Z]
    assert event.visitor_id =~ ~r/^[0-9a-f]{16}$/
    assert event.path == "/shop/mugs"
    assert event.source == "Instagram"
    assert event.channel == "Organic Social"
    assert event.utm == %{"source" => "insta", "medium" => "social"}
    assert event.country == "US"
    assert event.screen == "Mobile"
    assert event.browser == "Safari"
    assert event.os == "iOS"
    assert event.props == %{}
    assert event.revenue == nil
  end

  test "stores nothing that identifies the request" do
    {:ok, event} = Ingest.build_event(body(), request())
    encoded = Jason.encode!(event)

    refute encoded =~ "203.0.113.7"
    refute encoded =~ "iPhone OS"
    refute encoded =~ "l.instagram.com"
    refute encoded =~ "390"
  end

  test "keeps custom properties and revenue on goal events" do
    payload =
      body(%{
        "n" => "Purchase",
        "p" => %{"collection" => "fall-glaze"},
        "$" => %{"amount" => 64.0, "currency" => "usd"}
      })

    assert {:ok, event} = Ingest.build_event(payload, request())
    assert event.name == "Purchase"
    assert event.props == %{"collection" => "fall-glaze"}
    assert event.revenue == %{amount: 64.0, currency: "USD"}
  end

  test "the same visitor gets the same id on the same day" do
    {:ok, a} = Ingest.build_event(body(), request())
    {:ok, b} = Ingest.build_event(body(%{"u" => "https://harrowfield.co/cart"}), request())
    {:ok, other} = Ingest.build_event(body(), %{request() | headers: [{"user-agent", @ua}]})

    assert a.visitor_id == b.visitor_id
    refute a.visitor_id == other.visitor_id
  end

  test "accepts www. variants of a configured site" do
    assert {:ok, %{site: "harrowfield.co"}} =
             Ingest.build_event(body(%{"d" => "www.harrowfield.co"}), request())
  end

  test "drops bots and unknown sites" do
    bot = %{request() | headers: [{"user-agent", "Googlebot/2.1"}]}
    assert Ingest.build_event(body(), bot) == {:drop, :bot}
    assert Ingest.build_event(body(), %{request() | headers: []}) == {:drop, :bot}

    assert Ingest.build_event(body(%{"d" => "unknown.example"}), request()) ==
             {:drop, :unknown_site}
  end

  test "returns validation errors" do
    assert Ingest.build_event("{", request()) == {:error, :invalid_json}

    assert {:error, {:invalid, %{"w" => _}}} =
             Ingest.build_event(body(%{"w" => "wide"}), request())
  end

  describe "normalize_path/1" do
    test "strips trailing slashes and decodes" do
      assert Ingest.normalize_path("/") == "/"
      assert Ingest.normalize_path("/journal/how-we-glaze/") == "/journal/how-we-glaze"
      assert Ingest.normalize_path("/shop/caf%C3%A9") == "/shop/café"
      assert Ingest.normalize_path("/bad%E0%A4%A") == "/bad%E0%A4%A"
    end

    test "caps very long paths" do
      assert ("/" <> String.duplicate("a", 600)) |> Ingest.normalize_path() |> String.length() ==
               512
    end
  end
end

defmodule Tally.Ingest.PayloadTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Payload

  @valid %{
    "n" => "pageview",
    "u" => "https://harrowfield.co/shop/mugs?utm_source=insta",
    "r" => "https://www.google.com/",
    "w" => 1280,
    "d" => "harrowfield.co"
  }

  defp errors(map) do
    assert {:error, {:invalid, errors}} = Payload.validate(map)
    errors
  end

  describe "parse/1" do
    test "decodes and validates a beacon body" do
      assert {:ok, %Payload{} = payload} = @valid |> Jason.encode!() |> Payload.parse()
      assert payload.name == "pageview"
      assert payload.url.host == "harrowfield.co"
      assert payload.url.path == "/shop/mugs"
      assert payload.referrer == "https://www.google.com/"
      assert payload.width == 1280
      assert payload.domain == "harrowfield.co"
      assert payload.props == %{}
      assert payload.revenue == nil
    end

    test "rejects bodies that are not JSON" do
      assert Payload.parse("n=pageview") == {:error, :invalid_json}
      assert Payload.parse("") == {:error, :invalid_json}
    end

    test "rejects JSON that is not an object" do
      assert {:error, {:invalid, %{"_" => ["must be a JSON object"]}}} = Payload.parse("[1,2]")
    end

    test "rejects oversized bodies before decoding" do
      body = Jason.encode!(Map.put(@valid, "p", %{"x" => String.duplicate("a", 20_000)}))
      assert {:error, {:invalid, %{"_" => ["body is too large"]}}} = Payload.parse(body)
    end
  end

  describe "validate/1 required fields" do
    test "reports every missing field" do
      assert errors(%{}) == %{
               "n" => ["is required"],
               "u" => ["is required"],
               "r" => ["is required"],
               "w" => ["is required"],
               "d" => ["is required"]
             }
    end

    test "referrer may be null or empty, which both mean no referrer" do
      assert {:ok, %{referrer: nil}} = Payload.validate(%{@valid | "r" => nil})
      assert {:ok, %{referrer: nil}} = Payload.validate(%{@valid | "r" => ""})
    end

    test "event names are trimmed and limited to 120 characters" do
      assert {:ok, %{name: "Purchase"}} = Payload.validate(%{@valid | "n" => "  Purchase "})
      assert errors(%{@valid | "n" => "   "}) == %{"n" => ["must not be blank"]}

      assert errors(%{@valid | "n" => String.duplicate("x", 121)}) ==
               %{"n" => ["must be at most 120 characters"]}

      assert errors(%{@valid | "n" => 42}) == %{"n" => ["must be a string"]}
    end

    test "the page URL must be absolute http(s)" do
      for bad <- ["/shop/mugs", "ftp://harrowfield.co/", "javascript:alert(1)", "https://"] do
        assert errors(%{@valid | "u" => bad}) == %{"u" => ["must be an absolute http(s) URL"]}
      end

      long = "https://harrowfield.co/" <> String.duplicate("a", 2048)
      assert errors(%{@valid | "u" => long}) == %{"u" => ["must be at most 2048 characters"]}
    end

    test "width is an integer between 0 and 10,000" do
      assert {:ok, %{width: 0}} = Payload.validate(%{@valid | "w" => 0})
      assert errors(%{@valid | "w" => -1}) == %{"w" => ["must be between 0 and 10000"]}
      assert errors(%{@valid | "w" => 10_001}) == %{"w" => ["must be between 0 and 10000"]}
      assert errors(%{@valid | "w" => 390.5}) == %{"w" => ["must be an integer"]}
      assert errors(%{@valid | "w" => "390"}) == %{"w" => ["must be an integer"]}
    end

    test "domains are trimmed and lowercased" do
      assert {:ok, %{domain: "harrowfield.co"}} =
               Payload.validate(%{@valid | "d" => " Harrowfield.CO "})

      assert errors(%{@valid | "d" => "ab"}) == %{"d" => ["must be at least 3 characters"]}
      assert errors(%{@valid | "d" => "harrow field.co"}) == %{"d" => ["must be a domain name"]}
    end

    test "unknown keys are ignored" do
      assert {:ok, %Payload{}} = Payload.validate(Map.put(@valid, "x", "ignored"))
    end
  end

  describe "validate/1 custom properties" do
    test "accepts strings, numbers and booleans" do
      props = %{"form" => "footer", "step" => 2, "returning" => false}
      assert {:ok, %{props: ^props}} = Payload.validate(Map.put(@valid, "p", props))
    end

    test "rejects nested values and over-long keys or values" do
      props = %{
        "nested" => %{"a" => 1},
        String.duplicate("k", 65) => "x",
        "long" => String.duplicate("v", 257)
      }

      assert %{"p" => messages} = errors(Map.put(@valid, "p", props))
      assert "nested must be a string, number or boolean" in messages
      assert "long must be at most 256 characters" in messages
      assert Enum.any?(messages, &(&1 =~ "name must be at most 64 characters"))
    end

    test "limits the number of properties" do
      props = Map.new(1..31, &{"k#{&1}", &1})
      assert errors(Map.put(@valid, "p", props)) == %{"p" => ["must have at most 30 properties"]}
    end

    test "must be an object" do
      assert errors(Map.put(@valid, "p", ["a"])) == %{"p" => ["must be an object"]}
    end
  end

  describe "validate/1 revenue" do
    test "uppercases the currency" do
      payload = Map.put(@valid, "$", %{"amount" => 64.0, "currency" => "usd"})
      assert {:ok, %{revenue: %{amount: 64.0, currency: "USD"}}} = Payload.validate(payload)
    end

    test "rejects negative amounts, bad currencies and missing keys" do
      assert errors(Map.put(@valid, "$", %{"amount" => -1, "currency" => "USD"})) ==
               %{"$" => ["amount must not be negative"]}

      assert errors(Map.put(@valid, "$", %{"amount" => 1, "currency" => "US"})) ==
               %{"$" => ["currency must be a 3-letter ISO code"]}

      assert errors(Map.put(@valid, "$", %{"amount" => 1})) == %{"$" => ["missing currency"]}

      assert errors(Map.put(@valid, "$", %{})) == %{"$" => ["missing amount and currency"]}

      assert errors(Map.put(@valid, "$", %{"amount" => "64", "currency" => "USD"})) ==
               %{"$" => ["amount must be a number and currency a string"]}

      assert errors(Map.put(@valid, "$", 64)) ==
               %{"$" => ["must be an object with amount and currency"]}
    end
  end
end

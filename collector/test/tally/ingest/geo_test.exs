defmodule Tally.Ingest.GeoTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Geo

  describe "country/1" do
    test "reads edge geo headers in order of precedence" do
      assert Geo.country([{"cf-ipcountry", "CA"}, {"x-vercel-ip-country", "US"}]) == "CA"
      assert Geo.country([{"x-vercel-ip-country", "gb"}]) == "GB"
      assert Geo.country([{"X-Country-Code", "NZ"}]) == "NZ"
    end

    test "ignores placeholders and malformed values" do
      assert Geo.country([{"cf-ipcountry", "XX"}]) == nil
      assert Geo.country([{"cf-ipcountry", "T1"}]) == nil
      assert Geo.country([{"cf-ipcountry", "USA"}]) == nil
      assert Geo.country([{"cf-ipcountry", "XX"}, {"x-country-code", "DE"}]) == "DE"
      assert Geo.country([]) == nil
    end
  end

  describe "client_ip/2" do
    test "prefers the first x-forwarded-for address" do
      headers = [{"x-forwarded-for", "203.0.113.7, 10.0.0.2"}, {"x-real-ip", "10.0.0.9"}]
      assert Geo.client_ip(headers, {127, 0, 0, 1}) == "203.0.113.7"
    end

    test "falls back to x-real-ip, then the peer address" do
      assert Geo.client_ip([{"x-real-ip", "198.51.100.4"}], {127, 0, 0, 1}) == "198.51.100.4"
      assert Geo.client_ip([], {192, 168, 1, 20}) == "192.168.1.20"
      assert Geo.client_ip([], {0, 0, 0, 0, 0, 0, 0, 1}) == "::1"
      assert Geo.client_ip([]) == "0.0.0.0"
    end

    test "ignores blank forwarding headers" do
      assert Geo.client_ip([{"x-forwarded-for", " "}], {10, 0, 0, 1}) == "10.0.0.1"
    end
  end
end

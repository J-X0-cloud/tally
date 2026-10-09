defmodule Tally.Ingest.VisitorTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Salts
  alias Tally.Ingest.Visitor

  @ua "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) Safari/605.1.15"

  setup do
    name = :"visitor_salts_#{System.unique_integer([:positive])}"
    start_supervised!({Salts, name: name, schedule: false})
    %{salts: name}
  end

  test "is a 16-character hex string", %{salts: salts} do
    id = Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua, ~U[2026-09-25 14:40:00Z])
    assert id =~ ~r/^[0-9a-f]{16}$/
  end

  test "is stable within a day and changes across days", %{salts: salts} do
    morning = Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua, ~U[2026-09-25 08:00:00Z])
    evening = Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua, ~U[2026-09-25 23:59:00Z])
    tomorrow = Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua, ~U[2026-09-26 00:01:00Z])

    assert morning == evening
    refute morning == tomorrow
  end

  test "differs per site, IP and user agent", %{salts: salts} do
    now = ~U[2026-09-25 12:00:00Z]
    base = Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua, now)

    refute base == Visitor.id(salts, "example.org", "203.0.113.7", @ua, now)
    refute base == Visitor.id(salts, "harrowfield.co", "203.0.113.8", @ua, now)
    refute base == Visitor.id(salts, "harrowfield.co", "203.0.113.7", @ua <> " x", now)
  end

  test "hash/4 is sha256 of the concatenation, truncated" do
    expected =
      :crypto.hash(:sha256, "saltsiteipua") |> Base.encode16(case: :lower) |> binary_part(0, 16)

    assert Visitor.hash("salt", "site", "ip", "ua") == expected
  end
end

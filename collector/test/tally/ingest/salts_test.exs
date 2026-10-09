defmodule Tally.Ingest.SaltsTest do
  use ExUnit.Case, async: true

  alias Tally.Ingest.Salts

  setup context do
    name = :"salts_#{System.unique_integer([:positive])}_#{context.line}"
    start_supervised!({Salts, name: name, schedule: false})
    %{salts: name}
  end

  test "creates one 32-byte salt per day and reuses it", %{salts: salts} do
    salt = Salts.salt_for(salts, ~D[2026-09-25])
    assert byte_size(salt) == 32
    assert Salts.salt_for(salts, ~D[2026-09-25]) == salt
    refute Salts.salt_for(salts, ~D[2026-09-26]) == salt
  end

  test "concurrent first requests agree on the salt", %{salts: salts} do
    results =
      1..50
      |> Task.async_stream(fn _ -> Salts.salt_for(salts, ~D[2026-10-01]) end)
      |> Enum.map(fn {:ok, salt} -> salt end)
      |> Enum.uniq()

    assert length(results) == 1
  end

  test "rotation deletes every salt from before today", %{salts: salts} do
    for day <- [~D[2026-09-23], ~D[2026-09-24], ~D[2026-09-25]], do: Salts.salt_for(salts, day)

    assert Salts.rotate(salts, ~D[2026-09-25]) == 2
    assert Salts.days(salts) == [~D[2026-09-25]]
    assert Salts.rotate(salts, ~D[2026-09-25]) == 0
  end

  test "a rotated day gets a fresh salt if it is ever asked for again", %{salts: salts} do
    old = Salts.salt_for(salts, ~D[2026-09-24])
    Salts.rotate(salts, ~D[2026-09-25])
    refute Salts.salt_for(salts, ~D[2026-09-24]) == old
  end

  test "the scheduled rotation uses the injected clock" do
    name = :salts_clocked
    clock = fn -> ~U[2026-09-25 00:00:10Z] end
    pid = start_supervised!({Salts, name: name, clock: clock, schedule: false}, id: :clocked)

    Salts.salt_for(name, ~D[2026-09-24])
    Salts.salt_for(name, ~D[2026-09-25])
    send(pid, :rotate)
    # Wait for the message to be handled before reading the table.
    :sys.get_state(pid)

    assert Salts.days(name) == [~D[2026-09-25]]
  end

  test "ms_until_next_midnight/1" do
    assert Salts.ms_until_next_midnight(~U[2026-09-25 23:59:59Z]) == 1_000
    assert Salts.ms_until_next_midnight(~U[2026-09-25 00:00:00Z]) == 86_400_000
  end
end

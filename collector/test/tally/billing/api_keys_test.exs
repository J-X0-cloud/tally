defmodule Tally.Billing.ApiKeysTest do
  use ExUnit.Case, async: true

  alias Tally.Billing.ApiKeys

  test "lookup/1 returns the key's plan" do
    assert ApiKeys.lookup("test-growth") == {:ok, "growth"}
    assert ApiKeys.lookup("test-business") == {:ok, "business"}
  end

  test "lookup/1 rejects unknown, partial and empty keys" do
    assert ApiKeys.lookup("test-growt") == :error
    assert ApiKeys.lookup("test-growthx") == :error
    assert ApiKeys.lookup("") == :error
    assert ApiKeys.lookup(nil) == :error
  end

  test "fingerprint/1 is stable and doesn't contain the key" do
    assert ApiKeys.fingerprint("test-growth") == ApiKeys.fingerprint("test-growth")
    refute ApiKeys.fingerprint("test-growth") =~ "growth"
    assert byte_size(ApiKeys.fingerprint("test-growth")) == 12
  end
end

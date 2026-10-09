defmodule Tally.Stats.PathPatternTest do
  use ExUnit.Case, async: true

  alias Tally.Stats.PathPattern

  doctest PathPattern

  test "a pattern without wildcards is exact" do
    assert PathPattern.match?("/cart", "/cart")
    refute PathPattern.match?("/cart", "/cart/items")
    refute PathPattern.match?("/cart", "/carts")
  end

  test "* stays inside one segment" do
    assert PathPattern.match?("/shop/*", "/shop/mugs")
    assert PathPattern.match?("/shop/*", "/shop/")
    refute PathPattern.match?("/shop/*", "/shop/mugs/blue")
    assert PathPattern.match?("/products/*-mug", "/products/speckled-stoneware-mug")
  end

  test "** crosses segments" do
    assert PathPattern.match?("/journal/**", "/journal/how-we-glaze")
    assert PathPattern.match?("/journal/**", "/journal/2026/09/notes")
    refute PathPattern.match?("/journal/**", "/journals")
  end

  test "regex metacharacters are literal" do
    assert PathPattern.match?("/a.b", "/a.b")
    refute PathPattern.match?("/a.b", "/axb")
    assert PathPattern.match?("/(beta)", "/(beta)")
  end

  test "wildcard?/1" do
    assert PathPattern.wildcard?("/products/*")
    refute PathPattern.wildcard?("/cart")
  end
end

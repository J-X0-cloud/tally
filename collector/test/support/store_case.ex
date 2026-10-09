defmodule Tally.StoreCase do
  @moduledoc """
  Test case for tests that read or write the shared `Tally.Events.Store`. Runs synchronously and
  starts every test with an empty store.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Tally.Factory
    end
  end

  setup do
    Tally.Events.Store.clear()
    on_exit(fn -> Tally.Events.Store.clear() end)
    :ok
  end
end

defmodule TallyWeb.ChannelCase do
  @moduledoc """
  Test case for channel tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import TallyWeb.ChannelCase
      import Tally.Factory

      @endpoint TallyWeb.Endpoint
    end
  end
end

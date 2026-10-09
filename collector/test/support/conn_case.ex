defmodule TallyWeb.ConnCase do
  @moduledoc """
  Test case for controller tests: builds a `Plug.Conn` and imports the Phoenix test helpers.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint TallyWeb.Endpoint

      import Plug.Conn
      import Phoenix.ConnTest
      import TallyWeb.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

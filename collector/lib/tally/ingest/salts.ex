defmodule Tally.Ingest.Salts do
  @moduledoc """
  Daily salts for visitor hashing.

  A random 32-byte salt is created the first time it is needed on each UTC day. Shortly after UTC
  midnight every older salt is deleted, so hashes can never be linked across days, not even by us.

  Salts live in a protected ETS table owned by this process: reads go straight to the table, and only
  creation and rotation go through the GenServer, which keeps concurrent ingest requests from racing
  to create two different salts for the same day.

  This store suits a single instance. A multi-instance deployment needs a shared store with the same
  behaviour (for example Redis keys with a 48-hour TTL).
  """
  use GenServer

  require Logger

  @salt_bytes 32

  @doc false
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  The salt for `day` (a `Date`), created on first use.
  """
  @spec salt_for(GenServer.server(), Date.t()) :: binary()
  def salt_for(server \\ __MODULE__, %Date{} = day) do
    case lookup(server, day) do
      {:ok, salt} -> salt
      :error -> GenServer.call(server, {:create, day})
    end
  end

  @doc """
  Deletes every salt from before `today`. Called automatically after UTC midnight; exposed for tests
  and manual rotation.
  """
  @spec rotate(GenServer.server(), Date.t()) :: non_neg_integer()
  def rotate(server \\ __MODULE__, %Date{} = today) do
    GenServer.call(server, {:rotate, today})
  end

  @doc """
  The days that currently have a salt.
  """
  @spec days(GenServer.server()) :: [Date.t()]
  def days(server \\ __MODULE__) do
    server |> table() |> :ets.tab2list() |> Enum.map(&elem(&1, 0)) |> Enum.sort(Date)
  end

  # -- server -------------------------------------------------------------------------------------

  @impl true
  def init(opts) do
    table =
      case Keyword.get(opts, :name, __MODULE__) do
        name when is_atom(name) ->
          :ets.new(table_name(name), [:set, :protected, :named_table, read_concurrency: true])

        _ ->
          :ets.new(:tally_salts, [:set, :protected, read_concurrency: true])
      end

    clock = Keyword.get(opts, :clock, &DateTime.utc_now/0)
    state = %{table: table, clock: clock, schedule?: Keyword.get(opts, :schedule, true)}
    {:ok, schedule_rotation(state)}
  end

  @impl true
  def handle_call(:table, _from, state), do: {:reply, state.table, state}

  def handle_call({:create, day}, _from, state) do
    salt =
      case :ets.lookup(state.table, day) do
        [{^day, salt}] ->
          salt

        [] ->
          salt = :crypto.strong_rand_bytes(@salt_bytes)
          :ets.insert(state.table, {day, salt})
          salt
      end

    {:reply, salt, state}
  end

  def handle_call({:rotate, today}, _from, state) do
    {:reply, delete_before(state.table, today), state}
  end

  @impl true
  def handle_info(:rotate, state) do
    today = DateTime.to_date(state.clock.())
    deleted = delete_before(state.table, today)

    if deleted > 0 do
      Logger.info("Rotated visitor salts: deleted #{deleted} salt(s) from before #{today}")
    end

    {:noreply, schedule_rotation(state)}
  end

  defp delete_before(table, today) do
    match_spec = [{{:"$1", :_}, [], [:"$1"]}]

    table
    |> :ets.select(match_spec)
    |> Enum.filter(&(Date.compare(&1, today) == :lt))
    |> Enum.map(&:ets.delete(table, &1))
    |> length()
  end

  # Rotation runs a few seconds after the next UTC midnight.
  defp schedule_rotation(%{schedule?: false} = state), do: state

  defp schedule_rotation(state) do
    Process.send_after(self(), :rotate, ms_until_next_midnight(state.clock.()) + 5_000)
    state
  end

  @doc false
  @spec ms_until_next_midnight(DateTime.t()) :: non_neg_integer()
  def ms_until_next_midnight(%DateTime{} = now) do
    next_midnight = DateTime.new!(Date.add(DateTime.to_date(now), 1), ~T[00:00:00], "Etc/UTC")
    max(DateTime.diff(next_midnight, now, :millisecond), 0)
  end

  defp lookup(server, day) do
    case :ets.lookup(table(server), day) do
      [{^day, salt}] -> {:ok, salt}
      [] -> :error
    end
  rescue
    # The table is briefly missing while the owner restarts; fall back to the server.
    ArgumentError -> :error
  end

  defp table(server) when is_atom(server), do: table_name(server)
  defp table(server), do: GenServer.call(server, :table)

  defp table_name(name), do: Module.concat(name, Table)
end

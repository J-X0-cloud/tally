defmodule Tally.Demo.Rng do
  @moduledoc """
  Seeded pseudo-random numbers for the demo traffic model: mulberry32, with the same 32-bit
  arithmetic as the JavaScript original, so a seed produces the same sequence everywhere.

  The generator is a plain value. Every draw returns the number and the next state, which keeps
  the model a pure function of its seed:

      iex> {x, _next} = Tally.Demo.Rng.next(Tally.Demo.Rng.new(11))
      iex> x
      0.5115870486479253
  """

  import Bitwise

  @enforce_keys [:state]
  defstruct [:state]

  @type t :: %__MODULE__{state: non_neg_integer()}

  @mask 0xFFFFFFFF
  @increment 0x6D2B79F5

  @doc "A generator for a seed (truncated to 32 bits)."
  @spec new(integer()) :: t()
  def new(seed) when is_integer(seed), do: %__MODULE__{state: seed &&& @mask}

  @doc "A float in `[0, 1)` and the next generator state."
  @spec next(t()) :: {float(), t()}
  def next(%__MODULE__{state: state}) do
    state = state + @increment &&& @mask
    t = imul(bxor(state, state >>> 15), state ||| 1)
    t = bxor(t, t + imul(bxor(t, t >>> 7), t ||| 61) &&& @mask)
    {bxor(t, t >>> 14) / 4_294_967_296, %__MODULE__{state: state}}
  end

  @doc "A float in `[min, max)` and the next generator state."
  @spec uniform(t(), number(), number()) :: {float(), t()}
  def uniform(rng, min, max) do
    {x, rng} = next(rng)
    {min + (max - min) * x, rng}
  end

  @doc """
  32-bit FNV-1a hash of a string, for deriving stable seeds from keys such as
  `"sources/channels/30d"`.

      iex> Tally.Demo.Rng.hash_seed("")
      2166136261
  """
  @spec hash_seed(String.t()) :: non_neg_integer()
  def hash_seed(key) when is_binary(key) do
    key
    |> utf16_units()
    |> Enum.reduce(0x811C9DC5, fn unit, hash -> imul(bxor(hash, unit), 0x01000193) end)
  end

  # Math.imul: the low 32 bits of the product.
  defp imul(a, b), do: a * b &&& @mask

  # JavaScript's charCodeAt works on UTF-16 code units.
  defp utf16_units(string) do
    for <<unit::16 <- :unicode.characters_to_binary(string, :utf8, :utf16)>>, do: unit
  end
end

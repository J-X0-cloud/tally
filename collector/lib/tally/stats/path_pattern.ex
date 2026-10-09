defmodule Tally.Stats.PathPattern do
  @moduledoc """
  Wildcard patterns for page paths, used by page goals, funnel steps and page filters.

    * `*` matches any characters within one path segment (`/products/*` matches
      `/products/ash-glaze-bowl-set` but not `/products/a/b`);
    * `**` matches across segments (`/journal/**` matches every page under `/journal/`);
    * everything else matches literally. A pattern without wildcards is an exact match.

  Patterns compile to anchored regular expressions once; `match?/2` accepts either form.
  """

  @enforce_keys [:source, :regex]
  defstruct [:source, :regex]

  @type t :: %__MODULE__{source: String.t(), regex: Regex.t()}

  @doc """
  Compiles a pattern.

      iex> pattern = Tally.Stats.PathPattern.compile("/products/*")
      iex> Tally.Stats.PathPattern.match?(pattern, "/products/speckled-stoneware-mug")
      true
      iex> Tally.Stats.PathPattern.match?(pattern, "/products/a/b")
      false
  """
  @spec compile(String.t()) :: t()
  def compile(source) when is_binary(source) do
    body =
      source
      |> String.split("**")
      |> Enum.map_join(".*", fn part ->
        part |> String.split("*") |> Enum.map_join("[^/]*", &Regex.escape/1)
      end)

    %__MODULE__{source: source, regex: Regex.compile!("^" <> body <> "$")}
  end

  @doc """
  Whether `path` matches the pattern. A string pattern is compiled on the fly.
  """
  @spec match?(t() | String.t(), String.t()) :: boolean()
  def match?(%__MODULE__{regex: regex}, path) when is_binary(path), do: Regex.match?(regex, path)

  def match?(source, path) when is_binary(source),
    do: source |> compile() |> __MODULE__.match?(path)

  @doc "Whether a pattern contains wildcards."
  @spec wildcard?(String.t()) :: boolean()
  def wildcard?(source), do: String.contains?(source, "*")
end

defmodule TallyWeb.Params do
  @moduledoc """
  Small helpers for reading query parameters in controllers. Every helper returns `{:ok, value}` or
  `{:error, {:bad_request, message}}`, so controllers can chain them in a `with`.
  """

  @doc """
  Reads a required, non-blank string parameter.
  """
  @spec required(map(), String.t()) :: {:ok, String.t()} | {:error, {:bad_request, String.t()}}
  def required(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) ->
        case String.trim(value) do
          "" -> {:error, {:bad_request, "#{key} must not be blank"}}
          trimmed -> {:ok, trimmed}
        end

      nil ->
        {:error, {:bad_request, "#{key} is required"}}

      _other ->
        {:error, {:bad_request, "#{key} must be a string"}}
    end
  end

  @doc """
  Reads an optional string parameter, falling back to `default` when it is absent or blank.
  """
  @spec optional(map(), String.t(), term()) :: {:ok, term()}
  def optional(params, key, default \\ nil) do
    case Map.get(params, key) do
      value when is_binary(value) ->
        case String.trim(value) do
          "" -> {:ok, default}
          trimmed -> {:ok, trimmed}
        end

      _ ->
        {:ok, default}
    end
  end

  @doc """
  Reads an optional parameter that must be one of `allowed`.
  """
  @spec one_of(map(), String.t(), [String.t()], String.t()) ::
          {:ok, String.t()} | {:error, {:bad_request, String.t()}}
  def one_of(params, key, allowed, default) do
    {:ok, value} = optional(params, key, default)

    if value in allowed do
      {:ok, value}
    else
      {:error, {:bad_request, "#{key} must be one of: #{Enum.join(allowed, ", ")}"}}
    end
  end

  @doc """
  Reads an optional integer parameter within `min..max`.
  """
  @spec integer(map(), String.t(), integer(), Range.t()) ::
          {:ok, integer()} | {:error, {:bad_request, String.t()}}
  def integer(params, key, default, min..max//_) do
    case optional(params, key) do
      {:ok, nil} ->
        {:ok, default}

      {:ok, raw} ->
        case Integer.parse(raw) do
          {value, ""} when value >= min and value <= max -> {:ok, value}
          _ -> {:error, {:bad_request, "#{key} must be an integer between #{min} and #{max}"}}
        end
    end
  end
end

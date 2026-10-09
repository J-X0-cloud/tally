defmodule Tally.Ingest do
  @moduledoc """
  Turns a tracking-script request into an anonymous `Tally.Events.Event`.

  The pipeline:

    1. decode and validate the payload (`Tally.Ingest.Payload`);
    2. drop bots and sites this deployment doesn't serve;
    3. derive the visitor id from the daily salt, site, IP and user agent (`Tally.Ingest.Visitor`);
    4. attribute the visit to a source and channel (`Tally.Ingest.Referrer`);
    5. classify the device and look up the country (`Tally.Ingest.Device`, `Tally.Ingest.Geo`).

  The IP and user agent are used in steps 3 and 5 only and are not part of the result.
  """

  alias Tally.Events.Event
  alias Tally.Ingest.Device
  alias Tally.Ingest.Geo
  alias Tally.Ingest.Payload
  alias Tally.Ingest.Referrer
  alias Tally.Ingest.Visitor
  alias Tally.Sites

  @type request :: %{
          required(:headers) => [{String.t(), String.t()}],
          optional(:remote_ip) => :inet.ip_address() | nil,
          optional(:received_at) => DateTime.t()
        }

  @type drop_reason :: :bot | :unknown_site
  @type result ::
          {:ok, Event.t()}
          | {:drop, drop_reason()}
          | {:error, :invalid_json}
          | {:error, {:invalid, Payload.errors()}}

  @doc """
  Builds an event from a raw request body and the request metadata.
  """
  @spec build_event(binary(), request(), keyword()) :: result()
  def build_event(body, request, opts \\ []) when is_binary(body) do
    with {:ok, payload} <- Payload.parse(body) do
      from_payload(payload, request, opts)
    end
  end

  @doc """
  Builds an event from an already validated payload.
  """
  @spec from_payload(Payload.t(), request(), keyword()) ::
          {:ok, Event.t()} | {:drop, drop_reason()}
  def from_payload(%Payload{} = payload, request, opts \\ []) do
    headers = Map.fetch!(request, :headers)
    user_agent = header(headers, "user-agent") || ""
    site = Sites.normalize(payload.domain)

    cond do
      Device.bot?(user_agent) ->
        {:drop, :bot}

      not Sites.allowed?(site) ->
        {:drop, :unknown_site}

      true ->
        now =
          request |> Map.get(:received_at, DateTime.utc_now()) |> DateTime.truncate(:millisecond)

        salts = Keyword.get(opts, :salts, Tally.Ingest.Salts)
        ip = Geo.client_ip(headers, Map.get(request, :remote_ip))
        attribution = Referrer.attribute(payload.url, payload.referrer)
        %{browser: browser, os: os} = Device.user_agent(user_agent)

        {:ok,
         %Event{
           site: site,
           name: payload.name,
           timestamp: now,
           visitor_id: Visitor.id(salts, site, ip, user_agent, now),
           path: normalize_path(payload.url.path),
           source: attribution.source,
           channel: attribution.channel,
           utm: attribution.utm,
           country: Geo.country(headers),
           screen: Device.screen_class(payload.width),
           browser: browser,
           os: os,
           props: payload.props,
           revenue: payload.revenue
         }}
    end
  end

  @doc """
  The path as reported: no query string or fragment, a leading slash, no trailing slash except for
  the root, and at most 512 bytes.

      iex> Tally.Ingest.normalize_path("/shop/mugs/")
      "/shop/mugs"
      iex> Tally.Ingest.normalize_path(nil)
      "/"
  """
  @spec normalize_path(String.t() | nil) :: String.t()
  def normalize_path(nil), do: "/"
  def normalize_path(""), do: "/"

  def normalize_path(path) when is_binary(path) do
    decoded = safe_decode(path)

    decoded
    |> String.trim_trailing("/")
    |> then(&if(String.starts_with?(&1, "/"), do: &1, else: "/" <> &1))
    |> String.slice(0, 512)
  end

  # Percent-decoding can fail outright or produce invalid UTF-8; either way keep the raw path.
  defp safe_decode(path) do
    decoded = URI.decode(path)
    if String.valid?(decoded), do: decoded, else: path
  rescue
    ArgumentError -> path
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {key, value} -> String.downcase(key) == name && value end)
  end
end

defmodule Flint.Providers.AdbFlightsApi do
  @moduledoc """
  AeroDataBox implementation of the `Flint.Providers.FlightsApiProvider` behaviour.
  """

  @behaviour Flint.Providers.FlightsApiBehaviour

  alias Flint.Providers.ApiFlight

  @doc """
  Returns a list of scheduled flights from the given airport on the given date.
  """
  @spec list_scheduled_flights(String.t(), Date.t()) :: {:ok, [ApiFlight.t()]}
  def list_scheduled_flights(origin_airport_code, departure_date) do
    iso_date = Date.to_iso8601(departure_date)

    {:ok,
     Enum.concat(
       list_flights_by_range(origin_airport_code, iso_date <> "T01:00", iso_date <> "T11:59"),
       list_flights_by_range(origin_airport_code, iso_date <> "T12:00", iso_date <> "T23:59")
     )}
  end

  @spec create_request() :: Req.Request.t()
  defp create_request() do
    api_key = Application.fetch_env!(:flint, :flights_api_key)
    base_url = "https://aerodatabox.p.rapidapi.com/"

    Req.new(
      base_url: base_url,
      headers: [{"x-rapidapi-key", api_key}, {"x-rapidapi-host", "aerodatabox.p.rapidapi.com"}]
    )
  end

  @spec fetch_scheduled_flights(String.t(), String.t(), String.t()) :: {:ok, Req.Response.t()}
  defp fetch_scheduled_flights(airport_code, from, to) do
    create_request()
    |> Req.get(
      url: "/flights/airports/icao/:airport_code/:from/:to",
      path_params: [airport_code: airport_code, from: from, to: to],
      params: [
        direction: "Departure",
        withCancelled: false,
        withCargo: false,
        withCodeshared: false,
        withLeg: false,
        withLocation: false,
        withPrivate: false
      ]
    )
  end

  @spec list_flights_by_range(String.t(), String.t(), String.t()) :: [ApiFlight.t()]
  defp list_flights_by_range(origin_icao_code, start_at, end_at) do
    {:ok, response} = fetch_scheduled_flights(origin_icao_code, start_at, end_at)

    response
    |> Map.get(:body)
    |> Map.get("departures")
    |> Enum.map(&Flint.Providers.AdbFlightNormalizer.normalize_flight(origin_icao_code, &1))
    |> Enum.filter(&Flint.Providers.ApiFlight.valid_api_flight?/1)
  end
end

defmodule Flint.Flights.ApiImpl do
  @moduledoc """
  Implements the behaviour defined in `Flint.Flights.ApiBehaviour`.
  """
  @behaviour Flint.Flights.ApiBehaviour

  @doc """
  Returns a list of scheduled flights from the given airport on the given date.
  """
  @spec list_scheduled_flights(String.t(), Date.t()) :: {:ok, list()}
  def list_scheduled_flights(airport_code, departure_date) do
    from = Date.to_iso8601(departure_date) <> "T00:00"
    to = Date.to_iso8601(departure_date) <> "T11:59"
    {:ok, first_response} = fetch_scheduled_flights(airport_code, from, to)

    from = Date.to_iso8601(departure_date) <> "T12:00"
    to = Date.to_iso8601(departure_date) <> "T23:59"
    {:ok, second_response} = fetch_scheduled_flights(airport_code, from, to)

    {:ok,
     Map.get(first_response.body, "departures") ++ Map.get(second_response.body, "departures")}
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
      url: "/flights/airports/iata/:airport_code/:from/:to",
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
end

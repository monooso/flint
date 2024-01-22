defmodule Flint.Flights do
  import Ecto.Query, only: [from: 2]
  alias Flint.Flights.Route
  alias Flint.Flights.Airline
  alias Flint.Flights.Airport
  alias Flint.Flights.Flight
  alias Flint.Repo

  @moduledoc """
  Functions for retrieving information about flights.
  """

  @type flights_list() :: list(Flight.t())

  @doc """
  Removes flights with a destination that is not present in both lists.
  """
  @spec filter_by_common_destination(flights_list(), flights_list()) ::
          {flights_list(), flights_list()}
  def filter_by_common_destination(alpha, bravo) do
    icao_codes =
      filter_common_icao_codes(
        extract_destination_icao_codes_from_flights(alpha),
        extract_destination_icao_codes_from_flights(bravo)
      )

    {
      filter_flights_by_destination_icao_codes(alpha, icao_codes),
      filter_flights_by_destination_icao_codes(bravo, icao_codes)
    }
  end

  @doc """
  Returns a list of airlines matching the given ICAO codes.
  """
  @spec list_airlines_by_icao_codes(list(String.t())) :: list(Airline.t())
  def list_airlines_by_icao_codes(codes),
    do: from(a in Airline, where: a.icao_code in ^codes) |> Repo.all()

  @doc """
  Returns a list of airports matching the given ICAO codes.
  """
  @spec list_airports_by_icao_codes(list(String.t())) :: list(Airport.t())
  def list_airports_by_icao_codes(codes),
    do: from(a in Airport, where: a.icao_code in ^codes) |> Repo.all()

  @doc """
  Returns a list of scheduled flights for the given airport and date.
  """
  @spec list_scheduled_flights(String.t(), Date.t()) :: {:ok, flights_list()}
  def list_scheduled_flights(origin_icao_code, departure_date) do
    {:ok, api_flights} = api_impl().list_scheduled_flights(origin_icao_code, departure_date)

    airlines =
      api_flights
      |> Enum.map(& &1.airline_icao_code)
      |> Enum.sort()
      |> Enum.dedup()
      |> list_airlines_by_icao_codes()
      |> index_list_by_icao_code()

    airports =
      api_flights
      |> Enum.map(& &1.destination_icao_code)
      |> Enum.concat([origin_icao_code])
      |> Enum.sort()
      |> Enum.dedup()
      |> list_airports_by_icao_codes()
      |> index_list_by_icao_code()

    parsed_flights =
      api_flights
      |> Enum.map(fn api_flight ->
        %Flight{
          airline: Map.get(airlines, api_flight.airline_icao_code),
          departs_at: api_flight.departs_at,
          flight_number: api_flight.flight_number,
          route: %Route{
            destination: Map.get(airports, api_flight.destination_icao_code),
            origin: Map.get(airports, api_flight.origin_icao_code)
          }
        }
      end)

    {:ok, parsed_flights}
  end

  defp api_impl(), do: Application.get_env(:flint, :flights, Flint.Providers.AdbFlightsApi)

  @spec extract_destination_icao_codes_from_flights(flights_list()) :: list(String.t())
  defp extract_destination_icao_codes_from_flights(flights),
    do: Enum.map(flights, fn %{route: %{destination: %{icao_code: icao_code}}} -> icao_code end)

  @spec filter_common_icao_codes(list(String.t()), list(String.t())) :: list(String.t())
  defp filter_common_icao_codes(alpha, bravo),
    do: MapSet.intersection(MapSet.new(alpha), MapSet.new(bravo)) |> MapSet.to_list()

  @spec filter_flights_by_destination_icao_codes(flights_list(), list(String.t())) ::
          flights_list()
  defp filter_flights_by_destination_icao_codes(flights, icao_codes),
    do: Enum.filter(flights, &(&1.route.destination.icao_code in icao_codes))

  @spec index_list_by_icao_code(list()) :: map()
  defp index_list_by_icao_code(list),
    do: Enum.reduce(list, %{}, fn item, acc -> Map.put(acc, item.icao_code, item) end)
end

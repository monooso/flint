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
    {:ok, scheduled_flights} = api_impl().list_scheduled_flights(origin_icao_code, departure_date)

    airlines =
      scheduled_flights
      |> Enum.map(&get_in(&1, ["airline", "icao"]))
      |> list_airlines_by_icao_codes()
      |> index_list_by_icao_code()

    airports =
      scheduled_flights
      |> Enum.map(&get_in(&1, ["movement", "airport", "icao"]))
      |> Enum.concat([origin_icao_code])
      |> list_airports_by_icao_codes()
      |> index_list_by_icao_code()

    parsed_flights =
      scheduled_flights
      |> Enum.map(fn scheduled_flight ->
        %Flight{
          airline: Map.get(airlines, get_in(scheduled_flight, ["airline", "icao"])),
          departs_at:
            scheduled_flight
            |> get_in(["movement", "scheduledTime", "utc"])
            |> convert_scheduled_time_string_to_datetime(),
          flight_number: Map.get(scheduled_flight, "number"),
          route: %Route{
            destination:
              Map.get(airports, get_in(scheduled_flight, ["movement", "airport", "icao"])),
            origin: Map.get(airports, origin_icao_code)
          }
        }
      end)

    {:ok, parsed_flights}
  end

  defp convert_scheduled_time_string_to_datetime(scheduled_time) do
    {:ok, datetime, _offset} =
      scheduled_time
      |> String.replace_suffix("Z", ":00Z")
      |> DateTime.from_iso8601()

    datetime
  end

  defp api_impl(), do: Application.get_env(:flint, :flights, Flint.Flights.ApiImpl)

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

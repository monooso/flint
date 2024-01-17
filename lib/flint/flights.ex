defmodule Flint.Flights do
  import Ecto.Query, only: [from: 2]
  alias Flint.Flights.Airline
  alias Flint.Flights.Destination
  alias Flint.Flights.Flight
  alias Flint.Repo

  @moduledoc """
  Functions for retrieving information about flights.
  """

  @type destinations_list() :: list(Destination.t())
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
  Returns a list of scheduled flights for the given airport and date.
  """
  @spec list_scheduled_flights(String.t(), Date.t()) :: {:ok, destinations_list()}
  def list_scheduled_flights(airport_code, departure_date) do
    {:ok, flights} = api_impl().list_scheduled_flights(airport_code, departure_date)

    {:ok,
     flights
     |> Enum.map(&parse_flight/1)
     |> then(&collate_flights/1)
     |> then(&sort_flights/1)}
  end

  defp api_impl() do
    Application.get_env(:flint, :flights, Flint.Flights.ApiImpl)
  end

  defp collate_flights(flights) do
    flights
    |> Enum.group_by(&get_in(&1, [:airport, :iata_code]))
    |> Map.values()
    |> Enum.map(fn flights_to_destination ->
      departures = flights_to_destination |> Enum.map(&Map.fetch!(&1, :departs_at)) |> Enum.sort()
      airport = flights_to_destination |> Enum.at(0) |> Map.get(:airport)

      %Destination{airport: airport, departures: departures}
    end)
  end

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

  defp parse_flight(%{"movement" => flight}) do
    %{
      airport: %{
        iata_code: get_in(flight, ["airport", "iata"]),
        name: get_in(flight, ["airport", "name"])
      },
      departs_at:
        get_in(flight, ["scheduledTime", "utc"])
        |> String.replace_suffix("Z", ":00Z")
        |> DateTime.from_iso8601()
        |> elem(1)
    }
  end

  defp sort_flights(flights),
    do: Enum.sort_by(flights, & &1.airport.name)
end

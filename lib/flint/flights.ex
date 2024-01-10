defmodule Flint.Flights do
  alias Flint.Flights.Destination

  @moduledoc """
  Functions for retrieving information about flights.
  """

  @type destinations_list() :: list(Destination.t())

  @doc """
  Removes destinations that are not present in both given lists.
  """
  @spec filter_common_destinations(destinations_list(), destinations_list()) ::
          {destinations_list(), destinations_list()}
  def filter_common_destinations(destinations_a, destinations_b) do
    iata_codes =
      filter_common_iata_codes(
        extract_iata_codes_from_destinations(destinations_a),
        extract_iata_codes_from_destinations(destinations_b)
      )

    {
      filter_destinations_by_iata_codes(destinations_a, iata_codes),
      filter_destinations_by_iata_codes(destinations_b, iata_codes)
    }
  end

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

  @spec extract_iata_codes_from_destinations(destinations_list()) :: list(String.t())
  defp extract_iata_codes_from_destinations(destinations),
    do: Enum.map(destinations, fn %{airport: %{iata_code: iata_code}} -> iata_code end)

  @spec filter_common_iata_codes(list(String.t()), list(String.t())) :: list(String.t())
  defp filter_common_iata_codes(first_list, second_list),
    do: MapSet.intersection(MapSet.new(first_list), MapSet.new(second_list)) |> MapSet.to_list()

  @spec filter_destinations_by_iata_codes(destinations_list(), list(String.t())) ::
          destinations_list()
  defp filter_destinations_by_iata_codes(destinations, iata_codes),
    do: Enum.filter(destinations, &(&1.airport.iata_code in iata_codes))

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

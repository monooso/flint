defmodule Flint.Flights do
  alias Flint.Flights.Destination

  @moduledoc """
  Functions for retrieving information about flights.
  """

  @doc """
  Returns a list of scheduled flights for the given airport and date.
  """
  @spec list_scheduled_flights(String.t(), Date.t()) :: {:ok, list(Destination.t())}
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

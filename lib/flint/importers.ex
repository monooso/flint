defmodule Flint.Importers do
  @moduledoc """
  Helper functions for importing data into the database.
  """

  alias NimbleCSV.RFC4180, as: CSV

  @doc """
  Import airlines from the data/airports.csv file.

  Removes inactive airlines, and those without a valid IATA and ICAO code.
  """
  def import_airlines() do
    Path.join([File.cwd!(), "data", "airlines.csv"])
    |> File.stream!(:line)
    |> CSV.parse_stream()
    |> Stream.map(&parse_airline/1)
    |> Enum.reject(&is_nil/1)
    |> remove_duplicate_airlines()
    |> insert_airlines()
  end

  @doc """
  Import airports from the data/airports.csv file.

  Removes closed airports, and those without a valid IATA and ICAO code.
  """
  def import_airports() do
    Path.join([File.cwd!(), "data", "airports.csv"])
    |> File.stream!(:line)
    |> CSV.parse_stream()
    |> Stream.map(&parse_airport/1)
    |> Enum.reject(&is_nil/1)
    |> remove_duplicate_airports()
    |> insert_airports()
  end

  defp insert_airports(airport_data),
    do: Flint.Repo.insert_all(Flint.Flights.Airport, airport_data)

  defp parse_airport([_id, _icao_code, "closed" | _rest]), do: nil
  defp parse_airport([_id, _icao_code, _type, "" | _rest]), do: nil
  defp parse_airport([_id, _icao_code, _type, _name, "" | _rest]), do: nil
  defp parse_airport([_id, _icao_code, _type, _name, _latitude, "" | _rest]), do: nil

  defp parse_airport([
         _id,
         _icao_code,
         _type,
         _name,
         _latitude,
         _longitude,
         _elevation,
         _continent,
         _iso_country,
         _iso_region,
         _municipality,
         _service,
         _gps_code,
         "" | _rest
       ]),
       do: nil

  defp parse_airport([
         _id,
         icao_code,
         _type,
         name,
         latitude,
         longitude,
         _elevation,
         _continent,
         _iso_country,
         _iso_region,
         _municipality,
         _service,
         _gps_code,
         iata_code | _rest
       ]) do
    %{
      icao_code: :binary.copy(icao_code),
      iata_code: :binary.copy(iata_code),
      latitude: parse_string_as_float(latitude),
      longitude: parse_string_as_float(longitude),
      name: :binary.copy(name)
    }
  end

  defp parse_string_as_float(input) do
    case String.contains?(input, ".") do
      true -> String.to_float(input)
      _ -> String.to_float(input <> ".0")
    end
  end

  defp remove_duplicate_airports(airport_data),
    do: Enum.uniq_by(airport_data, &Map.get(&1, :icao_code))

  defp insert_airlines(airline_data),
    do: Flint.Repo.insert_all(Flint.Flights.Airline, airline_data)

  defp parse_airline(["Private flight", _iata_code, _icao_code, _call_sign, _country, _active]),
    do: nil

  defp parse_airline([_name, "" | _rest]), do: nil
  defp parse_airline([_name, _iata_code, "" | _rest]), do: nil
  defp parse_airline([_name, _iata_code, _icao_code, _call_sign, _country, "N"]), do: nil

  defp parse_airline([name, iata_code, icao_code | _rest]) do
    %{
      icao_code: :binary.copy(icao_code),
      iata_code: :binary.copy(iata_code),
      name: :binary.copy(name)
    }
  end

  defp remove_duplicate_airlines(airline_data),
    do: Enum.uniq_by(airline_data, &Map.get(&1, :icao_code))
end

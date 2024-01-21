defmodule Flint.Providers.AdbFlightNormalizer do
  alias Flint.Providers.ApiFlight

  @doc """
  Converts data returned from the AeroDataBox API into an `ApiFlight` struct.
  """
  @spec normalize_flight(String.t(), map()) :: ApiFlight.t()
  def normalize_flight(origin_icao_code, flight) do
    flight = normalize_input_destination(flight)

    %ApiFlight{}
    |> populate_airline_icao_code(flight)
    |> populate_departs_at(flight)
    |> populate_destination_icao_code(flight)
    |> populate_flight_number(flight)
    |> populate_origin_icao_code(origin_icao_code)
  end

  @spec normalize_input_destination(map()) :: map()
  defp normalize_input_destination(%{"arrival" => arrival} = flight) when is_map(arrival),
    do: Map.put(flight, "destination", arrival)

  defp normalize_input_destination(%{"movement" => movement} = flight) when is_map(movement),
    do: Map.put(flight, "destination", movement)

  @spec normalize_non_empty_string(term(), function()) :: String.t() | nil
  defp normalize_non_empty_string("", _normalizer), do: nil

  defp normalize_non_empty_string(input, normalizer) when is_binary(input),
    do: normalizer.(input)

  defp normalize_non_empty_string(_input, _normalizer), do: nil

  @spec populate_airline_icao_code(ApiFlight.t(), map()) :: ApiFlight.t()
  defp populate_airline_icao_code(api_flight, %{"airline" => airline}) when is_map(airline) do
    icao_code = airline |> Map.get("icao") |> normalize_non_empty_string(&String.upcase/1)
    %ApiFlight{api_flight | airline_icao_code: icao_code}
  end

  defp populate_airline_icao_code(api_flight, _) do
    api_flight
  end

  @spec populate_departs_at(ApiFlight.t(), map()) :: ApiFlight.t()
  defp populate_departs_at(api_flight, %{"destination" => %{"scheduledTime" => schedule}})
       when is_map(schedule) do
    {:ok, datetime, _offset} =
      schedule
      |> Map.get("utc")
      |> normalize_non_empty_string(&String.replace_suffix(&1, "Z", ":00Z"))
      |> DateTime.from_iso8601()

    %ApiFlight{api_flight | departs_at: datetime}
  end

  defp populate_departs_at(api_flight, _) do
    api_flight
  end

  @spec populate_destination_icao_code(ApiFlight.t(), map()) :: ApiFlight.t()
  defp populate_destination_icao_code(api_flight, %{"destination" => %{"airport" => airport}})
       when is_map(airport) do
    icao_code = airport |> Map.get("icao") |> normalize_non_empty_string(&String.upcase/1)
    %ApiFlight{api_flight | destination_icao_code: icao_code}
  end

  defp populate_destination_icao_code(api_flight, _) do
    api_flight
  end

  @spec populate_flight_number(ApiFlight.t(), map()) :: ApiFlight.t()
  defp populate_flight_number(api_flight, %{"number" => number}) when is_binary(number) do
    %ApiFlight{api_flight | flight_number: normalize_non_empty_string(number, &String.upcase/1)}
  end

  defp populate_flight_number(api_flight, _) do
    api_flight
  end

  @spec populate_origin_icao_code(ApiFlight.t(), String.t()) :: ApiFlight.t()
  defp populate_origin_icao_code(api_flight, origin_icao_code) do
    %ApiFlight{api_flight | origin_icao_code: String.upcase(origin_icao_code)}
  end
end

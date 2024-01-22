defmodule Flint.Providers.ApiFlightTest do
  alias Flint.Providers.ApiFlight
  use ExUnit.Case, async: true

  describe "valid_api_flight?/1" do
    test "it returns true when given a fully populated ApiFlight struct" do
      assert %ApiFlight{
               airline_icao_code: "AUA",
               departs_at: DateTime.utc_now(),
               destination_icao_code: "LOWW",
               flight_number: "OS 458",
               origin_icao_code: "EGFF"
             }
             |> ApiFlight.valid_api_flight?()
    end

    test "it returns false if any of the struct fields are nil" do
      api_flight = %ApiFlight{
        airline_icao_code: "AUA",
        departs_at: DateTime.utc_now(),
        destination_icao_code: "LOWW",
        flight_number: "OS 458",
        origin_icao_code: "EGFF"
      }

      refute api_flight
             |> Map.put(:airline_icao_code, nil)
             |> ApiFlight.valid_api_flight?()

      refute api_flight
             |> Map.put(:departs_at, nil)
             |> ApiFlight.valid_api_flight?()

      refute api_flight
             |> Map.put(:destination_icao_code, nil)
             |> ApiFlight.valid_api_flight?()

      refute api_flight
             |> Map.put(:flight_number, nil)
             |> ApiFlight.valid_api_flight?()

      refute api_flight
             |> Map.put(:origin_icao_code, nil)
             |> ApiFlight.valid_api_flight?()
    end

    test "it returns false if when given anything other than an ApiFlight struct" do
      refute ApiFlight.valid_api_flight?(%{})
    end
  end
end

defmodule Flint.Providers.AdbFlightNormalizerTest do
  use ExUnit.Case, async: true

  alias Flint.Providers.AdbFlightNormalizer
  alias Flint.Providers.ApiFlight

  describe "normalize_flight/1" do
    setup do
      flight = %{
        "movement" => %{
          "airport" => %{
            "icao" => "LOWW",
            "iata" => "VIE",
            "name" => "Vienna"
          },
          "scheduledTime" => %{
            "utc" => "2024-02-22 06:00Z",
            "local" => "2024-02-22 06:00+00:00"
          },
          "terminal" => "2",
          "quality" => ["Basic"]
        },
        "number" => "OS 458",
        "status" => "Unknown",
        "codeshareStatus" => "Unknown",
        "isCargo" => false,
        "aircraft" => %{
          "model" => "Airbus A320 NEO"
        },
        "airline" => %{
          "name" => "Austrian",
          "iata" => "OS",
          "icao" => "AUA"
        }
      }

      %{flight: flight}
    end

    test "it returns an ApiFlight struct", %{flight: flight} do
      assert %ApiFlight{} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `airline_icao_code` value", %{flight: flight} do
      assert %ApiFlight{airline_icao_code: "AUA"} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `airline_icao_code` if the `airline` key is missing",
         %{flight: flight} do
      flight = Map.delete(flight, "airline")

      assert %ApiFlight{airline_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `airline_icao_code` if the `airline` key is nil",
         %{flight: flight} do
      flight = Map.put(flight, "airline", nil)

      assert %ApiFlight{airline_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `airline_icao_code` if the `airline.icao` key is missing",
         %{flight: flight} do
      flight = %{flight | "airline" => %{"name" => "Wibble Air"}}

      assert %ApiFlight{airline_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `airline_icao_code` if the `airline.icao` key is nil",
         %{flight: flight} do
      flight = %{flight | "airline" => %{"name" => "Wibble Air", "icao" => nil}}

      assert %ApiFlight{airline_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `airline_icao_code` if the `airline.icao` key is an empty string",
         %{flight: flight} do
      flight = %{flight | "airline" => %{"name" => "Wibble Air", "icao" => ""}}

      assert %ApiFlight{airline_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `departs_at` value from the `movement` key", %{flight: flight} do
      assert %ApiFlight{departs_at: ~U[2024-02-22 06:00:00Z]} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `departs_at` value from the `arrival` key", %{flight: flight} do
      flight = flight |> Map.put("arrival", flight["movement"]) |> Map.delete("movement")

      assert %ApiFlight{departs_at: ~U[2024-02-22 06:00:00Z]} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `departs_at` if the `scheduledTime` key is missing", %{flight: flight} do
      movement = Map.get(flight, "movement")
      flight = %{flight | "movement" => Map.delete(movement, "scheduledTime")}
      assert %ApiFlight{departs_at: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `departs_at` if the `scheduledTime` key is nil", %{flight: flight} do
      movement = Map.get(flight, "movement")
      flight = %{flight | "movement" => Map.put(movement, "scheduledTime", nil)}
      assert %ApiFlight{departs_at: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `departs_at` if the `scheduledTime` key is an empty string", %{
      flight: flight
    } do
      movement = Map.get(flight, "movement")
      flight = %{flight | "movement" => Map.put(movement, "scheduledTime", "")}
      assert %ApiFlight{departs_at: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `destination_icao_code` value from the `movement` key", %{flight: flight} do
      assert %ApiFlight{destination_icao_code: "LOWW"} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `destination_icao_code` value from the `arrival` key", %{flight: flight} do
      flight = flight |> Map.put("arrival", flight["movement"]) |> Map.delete("movement")

      assert %ApiFlight{destination_icao_code: "LOWW"} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `destination_icao_code` if the `airport` key is missing", %{
      flight: flight
    } do
      movement = Map.get(flight, "movement")
      flight = %{flight | "movement" => Map.delete(movement, "airport")}

      assert %ApiFlight{destination_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `destination_icao_code` if the `airport` key is nil", %{flight: flight} do
      movement = Map.get(flight, "movement")
      flight = %{flight | "movement" => Map.put(movement, "airport", nil)}

      assert %ApiFlight{destination_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `destination_icao_code` if the `airport.icao` key is missing", %{
      flight: flight
    } do
      airport = flight |> Map.get("movement") |> Map.get("airport") |> Map.delete("icao")
      flight = %{flight | "movement" => %{"airport" => airport}}

      assert %ApiFlight{destination_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `destination_icao_code` if the `airport.icao` key is nil", %{
      flight: flight
    } do
      airport = flight |> Map.get("movement") |> Map.get("airport") |> Map.put("icao", nil)
      flight = %{flight | "movement" => %{"airport" => airport}}

      assert %ApiFlight{destination_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `destination_icao_code` if the `airport.icao` key is an empty string",
         %{
           flight: flight
         } do
      airport = flight |> Map.get("movement") |> Map.get("airport") |> Map.put("icao", "")
      flight = %{flight | "movement" => %{"airport" => airport}}

      assert %ApiFlight{destination_icao_code: nil} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `flight_number` value", %{flight: flight} do
      assert %ApiFlight{flight_number: "OS 458"} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `flight_number` if the `number` key is missing", %{
      flight: flight
    } do
      flight = Map.delete(flight, "number")
      assert %ApiFlight{flight_number: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `flight_number` if the `number` key is nil", %{flight: flight} do
      flight = Map.put(flight, "number", nil)
      assert %ApiFlight{flight_number: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it does not set `flight_number` if the `number` key is an empty string", %{
      flight: flight
    } do
      flight = Map.put(flight, "number", "")
      assert %ApiFlight{flight_number: nil} = AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end

    test "it sets the `origin_icao_code` value", %{flight: flight} do
      assert %ApiFlight{origin_icao_code: "EGFF"} =
               AdbFlightNormalizer.normalize_flight("EGFF", flight)
    end
  end
end

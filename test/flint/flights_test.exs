defmodule Flint.FlightsTest do
  alias Flint.Flights.Destination
  alias Flint.Flights.Airline
  use Flint.DataCase, async: true
  alias Flint.Flights.Flight
  import Mox

  setup :verify_on_exit!

  defp sort_by_icao_code(items), do: Enum.sort_by(items, & &1.icao_code)

  describe "filter_common_destinations/2" do
    defp generate_flight(origin_code, destination_code) do
      %Flight{
        airline: %Flint.Flights.Airline{iata_code: "AAA", name: "Triple-A Airlines"},
        departs_at: DateTime.utc_now() |> DateTime.add(36000, :minute),
        flight_number: "AAA 123",
        route: %Flint.Flights.Route{
          destination: %Flint.Flights.Airport{icao_code: destination_code},
          origin: %Flint.Flights.Airport{icao_code: origin_code}
        }
      }
    end

    setup do
      flights_a = [
        generate_flight("HOME", "DAVE"),
        generate_flight("HOME", "BRAD"),
        generate_flight("HOME", "MARY")
      ]

      flights_b = [
        generate_flight("AWAY", "BRAD"),
        generate_flight("AWAY", "MARY"),
        generate_flight("AWAY", "JANE")
      ]

      %{flights_a: flights_a, flights_b: flights_b}
    end

    test "it returns a tuple containing two lists of flights", %{
      flights_a: alpha,
      flights_b: bravo
    } do
      assert {[%Flight{}, %Flight{}], [%Flight{}, %Flight{}]} =
               Flint.Flights.filter_by_common_destination(alpha, bravo)
    end

    test "it removes flights with a destination that is not present in both lists", %{
      flights_a: alpha,
      flights_b: bravo
    } do
      extract_destination_codes = fn flights ->
        flights
        |> Enum.map(fn %{route: %{destination: %{icao_code: code}}} -> code end)
        |> Enum.sort()
      end

      {result_a, result_b} = Flint.Flights.filter_by_common_destination(alpha, bravo)

      assert {["BRAD", "MARY"], ["BRAD", "MARY"]} =
               {extract_destination_codes.(result_a), extract_destination_codes.(result_b)}
    end
  end

  describe "list_airlines_by_icao_codes/1" do
    test "it returns a list of airlines matching the given ICAO codes" do
      assert [
               %Airline{icao_code: "KLM"},
               %Airline{icao_code: "VLG"}
             ] = Flint.Flights.list_airlines_by_icao_codes(["KLM", "VLG"]) |> sort_by_icao_code()
    end
  end

  describe "list_scheduled_flights/2" do
    test "it returns an {:ok, list()} tuple on success" do
      expect(FlightsApiMock, :list_scheduled_flights, fn _airport_code, _departure_date ->
        {:ok, []}
      end)

      assert {:ok, []} = Flint.Flights.list_scheduled_flights("CWL", ~D[2024-10-12])
    end

    test "it extracts the airport and departures information for each flight" do
      expect(FlightsApiMock, :list_scheduled_flights, fn _airport_code, _departure_date ->
        {:ok,
         [
           %{
             "aircraft" => %{"model" => "Airbus A320"},
             "airline" => %{"iata" => "VY", "icao" => "VLG", "name" => "Vueling"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "ALC", "icao" => "LEAL", "name" => "Alicante"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 17:00+00:00",
                 "utc" => "2024-02-17 17:00Z"
               }
             },
             "number" => "VY 1240",
             "status" => "Unknown"
           },
           %{
             "aircraft" => %{"model" => "Embraer 175"},
             "airline" => %{"iata" => "KL", "icao" => "KLM", "name" => "KLM"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "AMS", "icao" => "EHAM", "name" => "Amsterdam"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 17:25+00:00",
                 "utc" => "2024-02-17 17:25Z"
               }
             },
             "number" => "KL 1066",
             "status" => "Unknown"
           },
           %{
             "aircraft" => %{"model" => "ATR 72"},
             "airline" => %{"iata" => "EI", "icao" => "EIN", "name" => "Aer Lingus"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "BHD", "icao" => "EGAC", "name" => "Belfast"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 12:10+00:00",
                 "utc" => "2024-02-17 12:10Z"
               }
             },
             "number" => "EI 3621",
             "status" => "Unknown"
           },
           %{
             "aircraft" => %{"model" => "Embraer 175"},
             "airline" => %{"iata" => "KL", "icao" => "KLM", "name" => "KLM"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "AMS", "icao" => "EHAM", "name" => "Amsterdam"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 10:15+00:00",
                 "utc" => "2024-02-17 10:15Z"
               }
             },
             "number" => "KL 1060",
             "status" => "Unknown"
           },
           %{
             "aircraft" => %{"model" => "Airbus A320"},
             "airline" => %{"iata" => "VY", "icao" => "VLG", "name" => "Vueling"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "AGP", "icao" => "LEMG", "name" => "Málaga"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 15:10+00:00",
                 "utc" => "2024-02-17 15:10Z"
               }
             },
             "number" => "VY 1261",
             "status" => "Unknown"
           },
           %{
             "aircraft" => %{"model" => "ATR 72"},
             "airline" => %{"iata" => "T3", "icao" => "EZE", "name" => "Eastern Airways"},
             "codeshareStatus" => "Unknown",
             "isCargo" => false,
             "movement" => %{
               "airport" => %{"iata" => "ORY", "icao" => "LFPO", "name" => "Paris"},
               "quality" => ["Basic"],
               "scheduledTime" => %{
                 "local" => "2024-02-17 15:40+00:00",
                 "utc" => "2024-02-17 15:40Z"
               }
             },
             "number" => "T3 247",
             "status" => "Unknown"
           }
         ]}
      end)

      expected_result = [
        %Destination{
          airport: %{iata_code: "ALC", name: "Alicante"},
          departures: [~U[2024-02-17 17:00:00Z]]
        },
        %Destination{
          airport: %{iata_code: "AMS", name: "Amsterdam"},
          departures: [~U[2024-02-17 10:15:00Z], ~U[2024-02-17 17:25:00Z]]
        },
        %Destination{
          airport: %{iata_code: "BHD", name: "Belfast"},
          departures: [~U[2024-02-17 12:10:00Z]]
        },
        %Destination{
          airport: %{iata_code: "AGP", name: "Málaga"},
          departures: [~U[2024-02-17 15:10:00Z]]
        },
        %Destination{
          airport: %{iata_code: "ORY", name: "Paris"},
          departures: [~U[2024-02-17 15:40:00Z]]
        }
      ]

      assert {:ok, ^expected_result} = Flint.Flights.list_scheduled_flights("CWL", ~D[2024-10-12])
    end
  end
end

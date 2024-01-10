defmodule Flint.FlightsTest do
  use ExUnit.Case, async: true
  alias Flint.Flights.Destination
  import Mox

  setup :verify_on_exit!

  describe "filter_common_destinations/2" do
    setup do
      destinations_a = [
        %Destination{airport: %{iata_code: "AAA", name: "A"}},
        %Destination{airport: %{iata_code: "BBB", name: "B"}},
        %Destination{airport: %{iata_code: "CCC", name: "C"}}
      ]

      destinations_b = [
        %Destination{airport: %{iata_code: "BBB", name: "B"}},
        %Destination{airport: %{iata_code: "CCC", name: "C"}},
        %Destination{airport: %{iata_code: "DDD", name: "D"}}
      ]

      %{destinations_a: destinations_a, destinations_b: destinations_b}
    end

    test "it returns a tuple containing two lists of destinations", %{
      destinations_a: destinations_a,
      destinations_b: destinations_b
    } do
      assert {[%Destination{}, %Destination{}], [%Destination{}, %Destination{}]} =
               Flint.Flights.filter_common_destinations(destinations_a, destinations_b)
    end

    test "it removes destinations that are not present in both lists", %{
      destinations_a: destinations_a,
      destinations_b: destinations_b
    } do
      extract_iata_codes = fn destinations ->
        destinations
        |> Enum.map(fn %{airport: %{iata_code: iata_code}} -> iata_code end)
        |> Enum.sort()
      end

      {result_a, result_b} =
        Flint.Flights.filter_common_destinations(destinations_a, destinations_b)

      assert {["BBB", "CCC"], ["BBB", "CCC"]} =
               {extract_iata_codes.(result_a), extract_iata_codes.(result_b)}
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

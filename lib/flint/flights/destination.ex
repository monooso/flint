defmodule Flint.Flights.Destination do
  @type t() :: %__MODULE__{
          airport: %{
            iata_code: String.t(),
            name: String.t()
          },
          departures: [DateTime.t()]
        }

  defstruct airport: %{iata_code: "", name: ""},
            departures: []
end

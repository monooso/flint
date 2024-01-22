defmodule Flint.Flights.Flight do
  @moduledoc """
  A data structure representing a flight between two airports.
  """

  @type t() :: %__MODULE__{
          airline: Flint.Flights.Airline.t(),
          departs_at: DateTime.t(),
          flight_number: String.t(),
          route: Flint.Flights.Route.t()
        }

  @enforce_keys [:airline, :departs_at, :flight_number, :route]
  defstruct [:airline, :departs_at, :flight_number, :route]
end

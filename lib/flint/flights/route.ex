defmodule Flint.Flights.Route do
  @moduledoc """
  A data structure representing a route between two airports.
  """

  @type t() :: %__MODULE__{
          destination: Flint.Flights.Airport.t(),
          origin: Flint.Flights.Airport.t()
        }

  @enforce_keys [:destination, :origin]
  defstruct [:destination, :origin]
end

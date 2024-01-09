defmodule Flint.Flights.ApiBehaviour do
  @doc """
  Returns a list of scheduled flights for a given airport and date.
  """
  @callback list_scheduled_flights(airport_code :: String.t(), departure_date :: Date.t()) ::
              {:ok, term()} | {:error, term()}
end

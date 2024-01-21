defmodule Flint.Providers.FlightsApiBehaviour do
  @doc """
  Returns a list of scheduled flights for a given airport and date.
  """
  @callback list_scheduled_flights(airport_code :: String.t(), departure_date :: Date.t()) ::
              {:ok, [Flint.Providers.ApiFlight.t()]} | {:error, term()}
end

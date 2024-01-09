defmodule Flint.Flights.ApiImpl do
  @moduledoc """
  Implements the behaviour defined in `Flint.Flights.ApiBehaviour`.
  """
  @behaviour Flint.Flights.ApiBehaviour

  def list_scheduled_flights(_airport_code, _departure_date) do
    {:ok, []}
  end
end

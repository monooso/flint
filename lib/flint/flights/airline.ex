defmodule Flint.Flights.Airline do
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  schema "airlines" do
    field :icao_code, :string
    field :iata_code, :string
    field :name, :string
  end
end

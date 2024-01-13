defmodule Flint.Flights.Airport do
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  schema "airports" do
    field :iata_code, :string
    field :latitude, :float
    field :longitude, :float
    field :name, :string
  end
end

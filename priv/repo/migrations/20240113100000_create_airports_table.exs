defmodule Flint.Repo.Migrations.CreateAirportsTable do
  use Ecto.Migration

  @table_name :airports

  def change do
    create table(@table_name) do
      add :name, :string
      add :iata_code, :string
      add :latitude, :float
      add :longitude, :float
    end

    create index(@table_name, [:iata_code], unique: true)
  end
end

defmodule Flint.Repo.Migrations.CreateAirportsTable do
  use Ecto.Migration

  @table_name :airports

  def change do
    create table(@table_name) do
      add :name, :string, null: false
      add :icao_code, :string, null: false
      add :iata_code, :string, null: false
      add :latitude, :float, null: false
      add :longitude, :float, null: false
    end

    create index(@table_name, [:iata_code])
    create unique_index(@table_name, [:icao_code])
  end
end

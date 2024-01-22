defmodule Flint.Repo.Migrations.CreateAirlinesTable do
  use Ecto.Migration

  @table_name :airlines

  def change do
    create table(@table_name) do
      add :name, :string, null: false
      add :icao_code, :string, null: false
      add :iata_code, :string, null: false
    end

    create index(@table_name, [:iata_code])
    create unique_index(@table_name, [:icao_code])
  end
end

defmodule Flint.Flights.SearchForm do
  @moduledoc """
  Embedded schema for validating search form parameters.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :departure_date, :date
    field :first_origin_code, :string
    field :second_origin_code, :string
  end

  @doc """
  Returns a changeset for validating search form parameters.
  """
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(struct_or_changeset, params \\ %{}) do
    struct_or_changeset
    |> cast(params, [:first_origin_code, :second_origin_code, :departure_date])
    |> validate_required([:first_origin_code, :second_origin_code, :departure_date])
    |> validate_departure_date()
    |> validate_iata_code(:first_origin_code)
    |> validate_iata_code(:second_origin_code)
  end

  defp validate_departure_date(changeset) do
    with %Date{} = departure_date <- get_field(changeset, :departure_date),
         :gt <- Date.compare(departure_date, Date.utc_today()) do
      changeset
    else
      nil -> changeset
      _ -> add_error(changeset, :departure_date, "must be a future date")
    end
  end

  defp validate_iata_code(changeset, field),
    do: validate_format(changeset, field, ~r/^[A-Za-z]{3}$/, message: "must be a valid IATA code")
end

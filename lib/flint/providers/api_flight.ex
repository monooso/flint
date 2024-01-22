defmodule Flint.Providers.ApiFlight do
  @type t() :: %__MODULE__{
          airline_icao_code: String.t() | nil,
          departs_at: DateTime.t() | nil,
          destination_icao_code: String.t() | nil,
          flight_number: String.t() | nil,
          origin_icao_code: String.t() | nil
        }

  defstruct [
    :airline_icao_code,
    :departs_at,
    :destination_icao_code,
    :flight_number,
    :origin_icao_code
  ]

  @doc """
  Returns true if the given `api_flight` is a fully-populated `ApiFlight` struct, false otherwise.
  """
  @spec valid_api_flight?(any()) :: boolean()
  def valid_api_flight?(%__MODULE__{} = api_flight),
    do: api_flight |> Map.values() |> Enum.any?(&is_nil/1) |> Kernel.not()

  def valid_api_flight?(_), do: false
end

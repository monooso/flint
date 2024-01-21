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

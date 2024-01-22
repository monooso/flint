defmodule FlintWeb.Live.Search do
  use FlintWeb, :live_view
  alias Flint.Flights
  alias Flint.Flights.SearchForm

  @type flights_list() :: list(Flint.Flights.Flight.t())

  def mount(_params, _session, socket) do
    changeset =
      SearchForm.changeset(%SearchForm{
        first_origin_code: "EGLL",
        second_origin_code: "LFPO",
        departure_date: ~D[2024-02-22]
      })

    {:ok, socket |> assign_form(changeset)}
  end

  def handle_event("search", %{"search_form" => params}, socket) do
    result =
      %SearchForm{}
      |> SearchForm.changeset(params)
      |> Ecto.Changeset.apply_action(:validate)

    case result do
      {:ok, search_form} ->
        {_destinations_a, destinations_b} =
          search_form
          |> find_flights()
          |> find_common_destinations()

        destinations =
          Enum.map(destinations_b, fn flight ->
            destination = flight.route.destination

            %{
              label: "#{destination.name} (#{destination.iata_code})",
              lat: destination.latitude,
              lng: destination.longitude
            }
          end)

        {:noreply, push_event(socket, "destinations", %{destinations: destinations})}

      {:error, changeset} ->
        {:noreply, socket |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @spec find_flights(SearchForm.t()) :: {flights_list(), flights_list()}
  defp find_flights(%SearchForm{
         departure_date: date,
         first_origin_code: origin_a,
         second_origin_code: origin_b
       }) do
    {:ok, flights_a} = Flights.list_scheduled_flights(origin_a, date)
    {:ok, flights_b} = Flights.list_scheduled_flights(origin_b, date)

    {flights_a, flights_b}
  end

  @spec find_common_destinations({flights_list(), flights_list()}) ::
          {flights_list(), flights_list()}
  defp find_common_destinations({flights_a, flights_b}),
    do: Flights.filter_by_common_destination(flights_a, flights_b)
end

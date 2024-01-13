defmodule FlintWeb.Live.Search do
  use FlintWeb, :live_view
  alias Flint.Flights
  alias Flint.Flights.SearchForm

  @type destination_list() :: list(Flint.Flights.Destination.t())

  def mount(_params, _session, socket) do
    changeset = SearchForm.changeset(%SearchForm{})
    {:ok, socket |> assign_form(changeset) |> assign_results()}
  end

  def handle_event("search", %{"search_form" => params}, socket) do
    result =
      %SearchForm{}
      |> SearchForm.changeset(params)
      |> Ecto.Changeset.apply_action(:validate)

    {:noreply, socket}

    case result do
      {:ok, search_form} ->
        results =
          search_form
          |> find_flights()
          |> find_common_destinations()
          |> prepare_results(search_form)

        {:noreply, assign_results(socket, results)}

      {:error, changeset} ->
        {:noreply, socket |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_results(socket, results \\ []) do
    assign(socket, :results, results)
  end

  @spec find_flights(SearchForm.t()) :: {destination_list(), destination_list()}
  defp find_flights(%SearchForm{
         departure_date: date,
         first_origin_code: first_origin,
         second_origin_code: second_origin
       }) do
    {:ok, first_flights} = Flights.list_scheduled_flights(first_origin, date)
    {:ok, second_flights} = Flights.list_scheduled_flights(second_origin, date)

    {first_flights, second_flights}
  end

  @spec find_common_destinations({destination_list(), destination_list()}) ::
          {destination_list(), destination_list()}
  defp find_common_destinations({first_flights, second_flights}),
    do: Flights.filter_common_destinations(first_flights, second_flights)

  @spec prepare_results({destination_list(), destination_list()}, SearchForm.t()) :: map()
  defp prepare_results({first_destinations, second_destinations}, search_form) do
    rows = Enum.zip(first_destinations, second_destinations) |> Enum.map(&prepare_result_row/1)
    labels = ["Destination", search_form.first_origin_code, search_form.second_origin_code]

    %{labels: labels, rows: rows}
  end

  defp prepare_result_row(
         {%{airport: destination, departures: first_departures}, %{departures: second_departures}}
       ) do
    %{
      destination: destination,
      first_origin_departures: first_departures,
      second_origin_departures: second_departures
    }
  end
end

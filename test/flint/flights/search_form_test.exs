defmodule Flint.Flights.SearchFormTest do
  use ExUnit.Case, async: true
  import Flint.DataCase, only: [errors_on: 1]
  alias Ecto.Changeset
  alias Flint.Flights.SearchForm

  describe "changeset/2" do
    setup do
      future_date = Date.utc_today() |> Date.add(10)

      %{
        valid_params: %{
          "departure_date" => future_date,
          "first_origin_code" => "BRS",
          "second_origin_code" => "CWL"
        }
      }
    end

    test "it returns a valid changeset when given valid data", %{valid_params: params} do
      assert %Changeset{valid?: true} = SearchForm.changeset(%SearchForm{}, params)
    end

    test "it returns an invalid changeset when given invalid data" do
      assert %Changeset{valid?: false} = SearchForm.changeset(%SearchForm{}, %{})
    end

    test "a valid first_origin_code is required", %{valid_params: valid_params} do
      # It does not care about case.
      params = %{valid_params | "first_origin_code" => "BrS"}
      assert %{valid?: true} = SearchForm.changeset(%SearchForm{}, params)

      # Required.
      params = Map.delete(valid_params, "first_origin_code")
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{first_origin_code: ["can't be blank"]} = errors_on(changeset)

      # Must be a string.
      params = %{valid_params | "first_origin_code" => 123}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{first_origin_code: ["is invalid"]} = errors_on(changeset)

      # Must be three characters long.
      params = %{valid_params | "first_origin_code" => "BB"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{first_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)

      params = %{valid_params | "first_origin_code" => "BBBB"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{first_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)

      # Must only contain the letters A-Z or a-z.
      params = %{valid_params | "first_origin_code" => "B2B"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{first_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)
    end

    test "a valid second_origin_code is required", %{valid_params: valid_params} do
      # It does not care about case.
      params = %{valid_params | "second_origin_code" => "BrS"}
      assert %{valid?: true} = SearchForm.changeset(%SearchForm{}, params)

      # Required.
      params = Map.delete(valid_params, "second_origin_code")
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{second_origin_code: ["can't be blank"]} = errors_on(changeset)

      # Must be a string.
      params = %{valid_params | "second_origin_code" => 123}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{second_origin_code: ["is invalid"]} = errors_on(changeset)

      # Must be three characters long.
      params = %{valid_params | "second_origin_code" => "BB"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{second_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)

      params = %{valid_params | "second_origin_code" => "BBBB"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{second_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)

      # Must only contain the letters A-Z or a-z.
      params = %{valid_params | "second_origin_code" => "B2B"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{second_origin_code: ["must be a valid IATA code"]} = errors_on(changeset)
    end

    test "a valid departure_date is required", %{valid_params: valid_params} do
      # It accepts a valid Y-m-d string.
      date_string = Date.utc_today() |> Date.add(10) |> Date.to_iso8601()
      params = %{valid_params | "departure_date" => date_string}
      assert %{valid?: true} = SearchForm.changeset(%SearchForm{}, params)

      # Required.
      params = Map.delete(valid_params, "departure_date")
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{departure_date: ["can't be blank"]} = errors_on(changeset)

      # Must be a valid date or Y-m-d string.
      params = %{valid_params | "departure_date" => "24-02-17"}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{departure_date: ["is invalid"]} = errors_on(changeset)

      # Must be in the future.
      params = %{valid_params | "departure_date" => Date.utc_today()}
      changeset = SearchForm.changeset(%SearchForm{}, params)
      assert %{departure_date: ["must be a future date"]} = errors_on(changeset)
    end
  end
end

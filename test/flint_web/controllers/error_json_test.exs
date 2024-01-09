defmodule FlintWeb.ErrorJSONTest do
  use FlintWeb.ConnCase, async: true

  test "renders 404" do
    assert FlintWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert FlintWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

Mox.defmock(MockFlightsApi, for: Flint.Providers.FlightsApiBehaviour)
Application.put_env(:flint, :flights, MockFlightsApi)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Flint.Repo, :manual)

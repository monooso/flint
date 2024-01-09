Mox.defmock(FlightsApiMock, for: Flint.Flights.ApiBehaviour)
Application.put_env(:flint, :flights, FlightsApiMock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Flint.Repo, :manual)

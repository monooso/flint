defmodule Flint.Repo do
  use Ecto.Repo,
    otp_app: :flint,
    adapter: Ecto.Adapters.Postgres
end

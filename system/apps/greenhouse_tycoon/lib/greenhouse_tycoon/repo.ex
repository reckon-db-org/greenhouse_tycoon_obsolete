defmodule GreenhouseTycoon.Repo do
  use Ecto.Repo,
    otp_app: :greenhouse_tycoon,
    adapter: Ecto.Adapters.SQLite3
end

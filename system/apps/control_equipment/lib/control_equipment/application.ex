defmodule ControlEquipment.Application do
  @moduledoc """
  Application for controlling the operational state of greenhouse equipment.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ControlEquipment.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ControlEquipment.Supervisor}
    ]

    opts = [strategy: :one_for_one, name: ControlEquipment.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end


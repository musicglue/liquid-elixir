defmodule Liquid.Supervisor do
  @moduledoc """
  Supervisor for Liquid processes (currently empty)
  """
  use Supervisor

  @doc """
  Starts the liquid supervisor
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @doc """
  Actual supervisor init with no child processes to supervise yet
  """
  def init(:ok) do
    import Cachex.Spec, warn: false

    children = [
      worker(Cachex, [
        :parsed_template,
        [
          expiration:
            expiration(
              default: :timer.hours(12),
              interval: :timer.hours(12),
              lazy: true
            )
        ]
      ])
    ]

    opts = [strategy: :one_for_one, name: Liquid.Supervisor]
    supervise(children, opts)
  end
end

defmodule CBMQWriter do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(CBMQWriter.Worker, [arg1, arg2, arg3]),
      supervisor(CBMQWriter.Filesrv.Supervisor, [])
    ]

    :ets.new(:appstats, [:named_table, :set, :public])

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CBMQWriter.Supervisor]
    Supervisor.start_link(children, opts)
  end

#    CBMQWriter.Filesrv.Worker.recv_event(eventtype, sensorid, timestamp, payload)

  def incoming_increment(sensorid) do
    :ets.update_counter(:appstats, sensorid, {2,1})
  end
  def increment_received(sensorid) do
    :ets.update_counter(:appstats, sensorid, {3,1})
  end
  def disk_increment(sensorid, count) do
    :ets.update_counter(:appstats, sensorid, [{3, -count}, {4,count}])
  end


end

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
    returnme = Supervisor.start_link(children, opts)

    [
#      "ingress.event.procstart",
#      "ingress.event.procend",
#      "ingress.event.childproc",
#      "ingress.event.moduleload",
#      "ingress.event.module",
#      "ingress.event.filemod",
#      "ingress.event.regmod",
#      "ingress.event.netconn"
      "#"
    ]

    |> Enum.map(&spawn_event_stream/1)

    returnme
  end


  def spawn_event_stream(eventstream) do
    Supervisor.start_child(Cbserverapi2.Connection.Supervisor, [eventstream,  &to_sensor/1, &CBMQWriter.Creds.creds/0])
  end

  def to_sensor({
    {:"basic.deliver", _tag, _serial, _, "api.events", eventtype},
    {:amqp_msg, {:P_basic, "application/protobuf",_,_,_,_,_,_,_,_,_,_,_,_,_}, payload}}) do

    decodedmap = :sensor_events.decode_msg(payload, :CbEventMsg)
    timestamp  = decodedmap.header.timestamp
    sensorid   = decodedmap.env.endpoint."SensorId"

    CBMQWriter.Filesrv.Worker.recv_event(eventtype, sensorid, timestamp, payload)
  end

  def to_sensor({:"basic.consume_ok", _}) do IO.puts("Initialized") end
  def to_sensor(other) do end

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

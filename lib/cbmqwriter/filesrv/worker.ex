require Logger
defmodule CBMQWriter.Filesrv.Worker do
  use GenServer

  def recv_event(eventtype, sensorid, timestamp, binary) do
    case :gproc.lookup_local_name({:fileservworker, sensorid}) do
      :undefined ->
        {:ok, pid} = Supervisor.start_child(CBMQWriter.Filesrv.Supervisor, [sensorid])
        pid
      pid ->
        pid
    end

    lookuppid = :gproc.lookup_local_name({:fileservworker, sensorid})
    CBMQWriter.incoming_increment(eventtype)
    GenServer.cast(lookuppid, {:incoming_event, eventtype, sensorid, timestamp, binary})
    lookuppid
  end

  def start_link(sensorid) do
    GenServer.start_link(__MODULE__, sensorid, [fullsweep_after: 0])
  end



  def init(sensorid) do
    mypid = self
    case (:gproc.reg_or_locate({:n, :l, {:fileservworker, sensorid}})) do
      {^mypid, _} -> :erlang.send_after(10000, mypid, {:sync, sensorid})
                     {:ok, %{}}
      {pid, _}    -> :ignore
    end
  end

  def generate_path({:incoming_event, eventtype, sensorid, timestamp, binary}) do
    {{year,month,day},{hour,min,_}} = round(timestamp / 10000000) + 50522745600 |> :calendar.gregorian_seconds_to_datetime
    (:io_lib.format('data/~B/~4..0B/~2..0B/~2..0B/~2..0B/~1..0B', [sensorid, year,month,day,hour,div(min, 10)]) |> to_string) <> "/#{eventtype}"
  end

  def sync_file(sensorid, {filebase, queue}) do
    [_, path, eventtype] = Regex.run(~r/(.*)\/([^\/]*)$/, filebase)
    File.mkdir_p(path)
    binarylist = :queue.to_list(queue)

    CBMQWriter.disk_increment(eventtype, Enum.count(binarylist))
    CBMQWriter.File.append_chunks("#{filebase}.pbr", binarylist)
  end



  def handle_cast(fullev = {:incoming_event, eventtype, sensorid, timestamp, binary}, state) do
    gpath = generate_path(fullev)
    CBMQWriter.increment_received(eventtype)

    newq  = :queue.in({eventtype, binary}, Map.get(state, gpath, :queue.new))
    newstate = Map.put(state, gpath, newq)
    {:noreply, newstate}
  end

  def handle_info({:sync, sensorid}, state) do
    :gproc.goodbye

    send(self, {:disksync, sensorid})
    {:noreply, state}
  end
  def handle_info({:disksync, sensorid}, state) do
    Enum.map(state, &(sync_file(sensorid, &1)))
    {:stop, :normal, %{}}
  end

  def terminate(:normal, %{}) do
  end
  def terminate(:normal, state) do
    Logger.debug("Potential race condition - please check thy state #{inspect(state)}")
  end

end

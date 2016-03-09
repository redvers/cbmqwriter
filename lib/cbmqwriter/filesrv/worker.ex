require Logger
defmodule CBMQWriter.Filesrv.Worker do
  use GenServer

  def recv_event(eventtype, sensorid, timestamp, binary) do
    sendingpid =
    case Process.get(sensorid) do
      nil -> {:ok, pid} = Supervisor.start_child(CBMQWriter.Filesrv.Supervisor, [sensorid])
             Process.put(sensorid, pid)
             pid
      pid when is_pid(pid) -> pid
    end
    GenServer.cast(sendingpid, {:incoming_event, eventtype, sensorid, timestamp, binary})
  end

  def start_link(sensorid) do
    GenServer.start_link(__MODULE__, sensorid, [fullsweep_after: 0])
  end



  def init(sensorid) do
    :erlang.send_after(10000, self, {:sync, sensorid})
    {:ok, %{}}
  end

  def generate_path({:incoming_event, eventtype, sensorid, timestamp, _binary}) do
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
    send(self, {:gc, sensorid})
    Enum.map(state, &(sync_file(sensorid, &1)))

    {:noreply, %{}}
  end
  def handle_info({:gc, sensorid}, state) do
    :erlang.garbage_collect
    :erlang.send_after(10000, self, {:sync, sensorid})
    {:noreply, state}
  end

end

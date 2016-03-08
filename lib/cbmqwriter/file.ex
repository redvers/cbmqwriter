defmodule CBMQWriter.File do

  def iterate(filename, function) do
    iterate(:f2, filename, function)
  end

  def reduce(filename, function) do
    reduce(:f2, filename, function)
  end

  def append_chunks(filename, binaries) do
    append_chunks(:f2, filename, binaries)
  end





  defp append_chunks(:f2, filename, binaries) do
    pid = openfile(filename)
    Enum.map(binaries, &(add_chunk(pid, assemble_chunk(&1))))
    {pid, :ok} |> close_file
  end

  defp reduce(:f2, filename, function) do
    pid = openfile_ro(filename)
    reduce(:f2, [], pid, function, simple_read_record(pid, 0))
  end
  defp reduce(:f2, acc, pid, function, {{:ok, binary}, newoffset}) do
    reduce(:f2, [function.(binary) | acc], pid, function, simple_read_record(pid, newoffset))
  end
  defp reduce(:f2, acc, pid, _function, :eof) do
    :file.close(pid)
    Enum.reject(acc, &(&1 == nil))
  end


  defp iterate(:f2, filename, function) do
    pid = openfile_ro(filename)
    iterate(:f2, pid, function, simple_read_record(pid, 0))
  end
  defp iterate(:f2, pid, function, {{:ok, binary}, newoffset}) do
    function.(binary)
    iterate(:f2, pid, function, simple_read_record(pid, newoffset))
  end
  defp iterate(:f2, pid, _function, :eof) do
    :file.close(pid)
  end

  defp simple_read_record(pid, offset) do
    case :file.pread(pid, offset, 4) do
      :eof -> :eof
      {:ok, << size :: big-unsigned-size(32) >>} ->
        {:file.pread(pid, (offset + 4), size), offset + 4 + size}
    end
  end

  defp assemble_chunk({_, binary}) do
    << :erlang.byte_size(binary) :: size(32) >> <> binary
  end

  defp add_chunk(pid, binary) do
    :file.pwrite(pid, :eof, binary)
    pid
  end

  defp openfile(filename) do
    {:ok, pid} = File.open(String.to_char_list(filename), [:read, :write, :binary])
    pid
  end

  defp increment_counter(pid) do
    increment_counter(pid, 1)
  end

  defp increment_counter(pid, count) do
    case :file.pread(pid, {:bof, 0}, 4) do
      :eof -> :file.pwrite(pid, {:bof, 0}, << count :: big-unsigned-size(32) >>)
      {:ok, << current :: big-unsigned-size(32) >>}
           -> :file.pwrite(pid, {:bof, 0}, << (current + count) :: big-unsigned-size(32) >>)
    end
    pid
  end

  defp close_file({pid, result}) do
    :file.close(pid)
    result
  end

  defp openfile_ro(filename) do
    {:ok, pid} = File.open(String.to_char_list(filename), [:read, :binary])
    pid
  end
end

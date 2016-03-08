defmodule CBMQWriter.Creds do
  def creds do
    Map.new
    |> Map.put(:hostname, creddata.cbserverapi.hostname)
    |> Map.put(:username, creddata.cbserverapi.username)
    |> Map.put(:password, creddata.cbserverapi.password)
    |> Map.put(:port,     creddata.cbserverapi.port)
  end

  def creddata do
    :yamerl_constr.file('creds.yaml')
    |> List.flatten
    |> Enum.map(fn({key, value}) -> {List.to_atom(key), sublist(value)} end)
    |> Enum.into(Map.new)
  end

  defp sublist(keylist) do
    Enum.map(keylist, fn({k,v}) -> {List.to_atom(k), normalize_yaml_type(v)} end)
    |> Enum.into(Map.new)
  end

  defp normalize_yaml_type(x) when is_list(x), do: List.to_string(x)
  defp normalize_yaml_type(x) when is_integer(x), do: Integer.to_string(x)

end

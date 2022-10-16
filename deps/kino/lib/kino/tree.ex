defmodule Kino.Tree do
  use Kino.JS, assets_path: "lib/assets/tree"

  def new(data) do
    Kino.JS.new(__MODULE__, to_node(data))
  end

  defp to_node(string) when is_binary(string) do
    %{type: "string", value: string, children: nil}
  end

  defp to_node(atom) when is_atom(atom) do
    %{type: "atom", value: Atom.to_string(atom), children: nil}
  end

  defp to_node(integer) when is_integer(integer) do
    %{type: "integer", value: integer, children: nil}
  end

  defp to_node(float) when is_float(float) do
    %{type: "float", value: float, children: nil}
  end

  defp to_node(list) when is_list(list) do
    if Keyword.keyword?(list) do
      children = Enum.map(list, fn {key, value} -> to_key_value_node(key, value) end)
      %{type: "list", value: nil, children: children}
    else
      children = Enum.map(list, &to_node/1)
      %{type: "list", value: nil, children: children}
    end
  end

  defp to_node(tuple) when is_tuple(tuple) do
    # TODO: support records?
    children = tuple |> Tuple.to_list() |> Enum.map(&to_node/1)
    %{type: "tuple", value: nil, children: children}
  end

  defp to_node(%module{} = struct) when is_struct(struct) do
    children =
      struct
      |> Map.from_struct()
      |> Enum.map(fn {key, value} -> to_key_value_node(key, value) end)

    %{type: "struct", module: module_name(module), value: nil, children: children}
  end

  defp to_node(map) when is_map(map) do
    children =
      map
      |> Enum.sort_by(fn {key, _value} -> inspect(key) end)
      |> Enum.map(fn {key, value} -> to_key_value_node(key, value) end)

    %{type: "map", value: nil, children: children}
  end

  defp to_node(other) do
    %{type: "string", value: inspect(other), children: nil}
  end

  defp to_key_value_node(key, value) do
    # TODO: better handling of compound keys?
    simple_key =
      if is_binary(key) or is_atom(key) or is_number(key) do
        to_node(key)
      else
        %{type: "string", value: inspect(key), children: nil}
      end

    value |> to_node() |> Map.put(:key, simple_key)
  end

  defp module_name(module) do
    name = to_string(module)

    if String.starts_with?(name, "Elixir.") do
      String.slice(name, 7..-1)
    else
      name
    end
  end
end

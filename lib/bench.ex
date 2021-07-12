defmodule Bench do
  def run(count \\ 10000) do
    syn_ids = Enum.map(1..count, fn _num ->
      id = :rand.uniform(100_000_000)
      Dist.ItemSyn.start(id: id)

      id
    end)

    pg_ids = Enum.map(1..count, fn _num ->
      id = :rand.uniform(100_000_000)
      Dist.ItemPg.start(id: id)

      id
    end)

    horde_ids = Enum.map(1..count, fn _num ->
      id = :rand.uniform(100_000_000)

      Dist.ItemHorde.start(id: id)

      id
    end)

    Benchee.run(
      %{
        "syn" => fn -> Enum.each(syn_ids, fn id -> Dist.ItemSyn.hello(id) end) end,
        "horde" => fn -> Enum.each(horde_ids, fn id -> Dist.ItemHorde.hello(id) end) end,
        "pg" => fn -> Enum.each(pg_ids, fn id -> Dist.ItemPg.hello(id) end) end
      }
    )
  end
end
